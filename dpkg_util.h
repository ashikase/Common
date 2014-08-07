/**
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL, Version 3.0
 *          (See LICENSE file for details)
 */

#ifdef __cplusplus
extern "C" {
#endif

NSDictionary *detailsForDebianPackageWithIdentifier(NSString *identifier);
NSString *identifierForDebianPackageContainingFile(NSString *filepath);
NSDate *installDateForDebianPackageWithIdentifier(NSString *identifier);

#ifdef __cplusplus
}
#endif

/* vim: set ft=objc ff=unix sw=4 ts=4 expandtab tw=80: */
