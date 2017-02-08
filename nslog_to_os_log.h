/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, Version 2.0
 *          (See LICENSE file for details)
 */

#ifndef NSLOG_TO_OS_LOG_H_
#define NSLOG_TO_OS_LOG_H_

#include "firmware.h"

#define NSLog(FORMAT, ...)                                                           \
    if IOS_GTE(10_0) {                                                               \
        NSString *string = [NSString stringWithFormat:FORMAT, ##__VA_ARGS__];        \
        os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEFAULT, "%{public}@", string); \
    } else {                                                                         \
        NSLog(FORMAT, ##__VA_ARGS__);                                                \
    }                                                                                \

// NOTE: The remainder of this file contains extracts from os/log.h (iOS 10.2).

/*
 * Copyright (c) 2015-2016 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#include <os/object.h>

#if !__has_builtin(__builtin_os_log_format)
#error Using os_log requires Xcode 8 or later.
#endif

#define OS_LOG_FORMAT_ERRORS _Pragma("clang diagnostic error \"-Wformat\"")

extern struct mach_header __dso_handle;

OS_OBJECT_DECL(os_log);

#define OS_LOG_DEFAULT OS_OBJECT_GLOBAL_OBJECT(os_log_t, _os_log_default)

OS_ENUM(os_log_type, uint8_t,
        OS_LOG_TYPE_DEFAULT = 0x00,
        OS_LOG_TYPE_INFO    = 0x01,
        OS_LOG_TYPE_DEBUG   = 0x02,
        OS_LOG_TYPE_ERROR   = 0x10,
        OS_LOG_TYPE_FAULT   = 0x11);

#define os_log_with_type(log, type, format, ...) __extension__({ \
    if (os_log_type_enabled(log, type)) { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wvla\"") \
        OS_LOG_FORMAT_ERRORS \
        __attribute__((section("__TEXT,__oslogstring,cstring_literals"),internal_linkage)) static const char __format[] __asm(OS_STRINGIFY(OS_CONCAT(LOSLOG_, __COUNTER__))) = format; \
        uint8_t _os_log_buf[__builtin_os_log_format_buffer_size(format, ##__VA_ARGS__)]; \
        _os_log_impl(&__dso_handle, log, type, __format, (uint8_t *) __builtin_os_log_format(_os_log_buf, format, ##__VA_ARGS__), (unsigned int) sizeof(_os_log_buf)); \
        _Pragma("clang diagnostic pop") \
    } \
})

extern struct os_log_s *_os_log_default;
extern bool (*os_log_type_enabled)(os_log_t oslog, os_log_type_t type);
extern void (*_os_log_impl)(void *dso, os_log_t log, os_log_type_t type, const char *format, uint8_t *buf, unsigned int size);

#endif // NSLOG_TO_OS_LOG_H_

/* vim: set ft=objc ff=unix sw=4 ts=4 expandtab tw=80: */
