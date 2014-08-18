/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, Version 2.0
 *          (See LICENSE file for details)
 */

#ifndef NUMBER_FROM_STRING_H_
#define NUMBER_FROM_STRING_H_

#ifdef __cplusplus
extern "C" {
#endif

unsigned long long unsignedLongLongFromString(const char *string, int length);
unsigned long long unsignedLongLongFromHexString(const char *string, int length);

#ifdef __cplusplus
}
#endif

#endif

/* vim: set ft=c ff=unix sw=4 ts=4 tw=80 expandtab: */
