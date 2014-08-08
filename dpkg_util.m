/**
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL, Version 3.0
 *          (See LICENSE file for details)
 */

static NSDictionary *detailsFromDebianPackageQuery(FILE *f) {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];

    NSMutableData *data = [NSMutableData new];
    char buf[1025];
    size_t maxSize = (sizeof(buf) - 1);
    while (!feof(f)) {
        if (fgets(buf, maxSize, f)) {
            buf[maxSize] = '\0';

            char *newlineLocation = strrchr(buf, '\n');
            if (newlineLocation != NULL) {
                [data appendBytes:buf length:(NSUInteger)(newlineLocation - buf)];

                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSUInteger firstColon = [string rangeOfString:@":"].location;
                if (firstColon != NSNotFound) {
                    NSUInteger length = [string length];
                    if (length > (firstColon + 1)) {
                        NSCharacterSet *set = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
                        NSRange range = NSMakeRange((firstColon + 1), (length - firstColon - 1));
                        NSUInteger firstNonSpace = [string rangeOfCharacterFromSet:set options:0 range:range].location;
                        NSString *key = [string substringToIndex:firstColon];
                        NSString *value = [string substringFromIndex:firstNonSpace];
                        [details setObject:value forKey:key];
                    }
                }
                [string release];
                [data setLength:0];
            } else {
                [data appendBytes:buf length:maxSize];
            }
        }
    }
    [data release];

    return details;
}

NSDictionary *detailsForDebianPackageWithIdentifier(NSString *identifier) {
    NSDictionary *details = nil;

    // Backup stderr.
    int devStderr = dup(STDERR_FILENO);
    if (devStderr == -1) {
        fprintf(stderr, "ERROR: Failed to backup stderr: errno = %d.\n", errno);
    }

    // Redirect stderr to /dev/null.
    int devNull = open("/dev/null", O_WRONLY);
    if (dup2(devNull, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to redirect stderr to /dev/null for dpkg-query command: errno = %d.\n", errno);
    }

    // NOTE: Query using -p switch (/var/lib/dpkg/available) first, as package
    //       might have been uninstalled recently due to some issue.
    //       (Uninstalled packages will appear in 'status', but without any
    //       name/author information).
    FILE *f;
    NSString *query;

    query = [[NSString alloc] initWithFormat:@"dpkg-query -p \"%@\"", identifier];
    f = popen([query UTF8String], "r");
    [query release];

    int stat_loc = 0;
    if (f != NULL) {
        details = detailsFromDebianPackageQuery(f);
        stat_loc = pclose(f);
    }

    // Check the exit status to determine if the operation was successful.
    BOOL succeeded = NO;
    if (WIFEXITED(stat_loc)) {
        if (WEXITSTATUS(stat_loc) == 0) {
            succeeded = YES;
        }
    }

    // If command failed, try again using "-s" (/var/lib/dpkg/status) switch.
    if (!succeeded) {
        query = [[NSString alloc] initWithFormat:@"dpkg-query -s \"%@\"", identifier];
        f = popen([query UTF8String], "r");
        [query release];

        int stat_loc = 0;
        if (f != NULL) {
            // Determine name, author and version.
            details = detailsFromDebianPackageQuery(f);
            stat_loc = pclose(f);
        }
    }

    // Restore stderr.
    if (dup2(devStderr, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to restore stderr: errno = %d.\n", errno);
    }

    // Close duplicate file descriptors.
    close(devNull);
    close(devStderr);

    return details;
}

NSString *identifierForDebianPackageContainingFile(NSString *filepath) {
    NSString *identifier = nil;

    // Backup stderr.
    int devStderr = dup(STDERR_FILENO);
    if (devStderr == -1) {
        fprintf(stderr, "ERROR: Failed to backup stderr: errno = %d.\n", errno);
    }

    // Redirect stderr to /dev/null.
    int devNull = open("/dev/null", O_WRONLY);
    if (dup2(devNull, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to redirect stderr to /dev/null for dpkg-query command: errno = %d.\n", errno);
    }

    // Determine identifier of the package that contains the specified file.
    // NOTE: We need the slow way or we need to compile the whole dpkg.
    //       Not worth it for a minor feature like this.
    FILE *f = popen([[NSString stringWithFormat:@"dpkg-query -S \"%@\" | head -1", filepath] UTF8String], "r");
    if (f != NULL) {
        // NOTE: Since there's only 1 line, we can read until a , or : is hit.
        NSMutableData *data = [NSMutableData new];
        char buf[1025];
        size_t maxSize = (sizeof(buf) - 1);
        while (!feof(f)) {
            size_t actualSize = fread(buf, 1, maxSize, f);
            buf[actualSize] = '\0';
            size_t identifierSize = strcspn(buf, ",:");
            [data appendBytes:buf length:identifierSize];

            // TODO: What is the purpose of this line?
            if (identifierSize != maxSize) {
                break;
            }
        }
        if ([data length] > 0) {
            identifier = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        [data release];
        pclose(f);
    }

    // Restore stderr.
    if (dup2(devStderr, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to restore stderr: errno = %d.\n", errno);
    }

    // Close duplicate file descriptors.
    close(devNull);
    close(devStderr);

    return identifier;
}

NSDate *installDateForDebianPackageWithIdentifier(NSString *identifier) {
    NSDate *date = nil;

    // Determine the date that the package was installed (or last updated).
    // NOTE: Determined by looking at the modification date of the package
    //       contents list file.
    // XXX: If someone were to manually touch or edit this file, the "install
    //      date" would no longer be accurate.
    NSString *listPath = [[NSString alloc] initWithFormat:@"/var/lib/dpkg/info/%@.list", identifier];
    NSError *error = nil;
    NSDictionary *attrib = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:&error];
    if (attrib != nil) {
        date = [attrib fileModificationDate];
    } else {
        NSLog(@"ERROR: Failed to get attributes of package's info file: %@.", [error localizedDescription]);
    }
    [listPath release];

    return date;
}

/* vim: set ft=objc ff=unix sw=4 ts=4 expandtab tw=80: */
