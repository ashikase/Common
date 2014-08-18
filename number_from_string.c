/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, Version 2.0
 *          (See LICENSE file for details)
 */

// NOTE: Basic testing shows these versions to be around 4~8x faster than the
//       equivalent strtol/strtoll call.

unsigned long long unsignedLongLongFromString(const char *string, int length) {
    unsigned long long result = 0;
    int i;
    for (i = 0; i < length; ++i) {
        char c = string[i];
        if ((c >= '0') && (c <= '9')) {
            result = result * 10 + (c - '0');
        } else {
            break;
        }
    }
    return result;
}

unsigned long long unsignedLongLongFromHexString(const char *string, int length) {
    unsigned long long result = 0;
    int i;
    for (i = 0; i < length; ++i) {
        char c = string[i];
        if ((c >= '0') && (c <= '9')) {
            result = result * 16 + (c - '0');
        } else if ((c >= 'a') && (c <= 'f')) {
            result = result * 16 + (c - 'a' + 10);
        } else if ((c >= 'A') && (c <= 'F')) {
            result = result * 16 + (c - 'A' + 10);
        } else {
            break;
        }
    }
    return result;
}

/* vim: set ft=c ff=unix sw=4 ts=4 tw=80 expandtab: */
