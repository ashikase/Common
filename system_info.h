/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, Version 2.0
 *          (See LICENSE file for details)
 */

#include <dlfcn.h>
#include <sys/sysctl.h>
#include <sys/types.h>

#include "firmware.h"

typedef void* LockdownConnectionRef;

static inline NSString *platformVersion() {
    NSString *ret = nil;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *system = (char *)malloc(size * sizeof(char));
    if (sysctlbyname("hw.machine", system, &size, NULL, 0) != -1) {
        ret = [NSString stringWithCString:system encoding:NSASCIIStringEncoding];
        free(system);
    }
    return ret;
}

// NOTE: This is used in crash reports as the "CrashReporter Key".
static inline NSString *inverseDeviceIdentifier() {
    NSString *ret = nil;

    CFPropertyListRef value = NULL;
    if (IOS_LT(4_2)) {
        // NOTE: Avoid linking to liblockdown as we do not use it for newer iOS versions.
        void *handle = dlopen("/usr/lib/liblockdown.dylib", RTLD_LAZY);
        if (handle != NULL) {
            CFStringRef *kLockdownInverseDeviceIDKey = (CFStringRef *)dlsym(handle, "kLockdownInverseDeviceIDKey");
            LockdownConnectionRef (*lockdown_connect)(void) = (LockdownConnectionRef (*)(void))dlsym(handle, "lockdown_connect");
            void (*lockdown_disconnect)(LockdownConnectionRef) = (void (*)(LockdownConnectionRef))dlsym(handle, "lockdown_disconnect");
            CFPropertyListRef (*lockdown_copy_value)(LockdownConnectionRef, CFStringRef, CFStringRef) = (CFPropertyListRef (*)(LockdownConnectionRef, CFStringRef, CFStringRef))dlsym(handle, "lockdown_copy_value");

            if ((kLockdownInverseDeviceIDKey != NULL) &&
                    (lockdown_connect != NULL) &&
                    (lockdown_copy_value != NULL) &&
                    (lockdown_disconnect != NULL)
               ) {
                LockdownConnectionRef lockdown = lockdown_connect();
                if (lockdown != NULL) {
                    value = (CFStringRef)lockdown_copy_value(lockdown, NULL, *kLockdownInverseDeviceIDKey);
                    lockdown_disconnect(lockdown);
                }
            }
            dlclose(handle);
        }
    } else {
        // NOTE: Can't link to dylib as it doesn't exist in older iOS versions.
        void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
        if (handle != NULL) {
            CFPropertyListRef (*MGCopyAnswer)(CFStringRef) = (CFPropertyListRef (*)(CFStringRef))dlsym(handle, "MGCopyAnswer");
            if (MGCopyAnswer != NULL) {
                value = MGCopyAnswer(CFSTR("InverseDeviceID"));
            }
            dlclose(handle);
        }
    }

    if (value != NULL) {
        if (CFGetTypeID(value) == CFStringGetTypeID()) {
            ret = [NSString stringWithString:(NSString *)value];
        }
        CFRelease(value);
    }

    return ret;
}

static inline NSString *uniqueDeviceIdentifier() {
    NSString *ret = nil;

    CFPropertyListRef value = NULL;
    if (IOS_LT(4_2)) {
        // NOTE: Avoid linking to liblockdown as we do not use it for newer iOS versions.
        void *handle = dlopen("/usr/lib/liblockdown.dylib", RTLD_LAZY);
        if (handle != NULL) {
            CFStringRef *kLockdownUniqueDeviceIDKey = (CFStringRef *)dlsym(handle, "kLockdownUniqueDeviceIDKey");
            LockdownConnectionRef (*lockdown_connect)(void) = (LockdownConnectionRef (*)(void))dlsym(handle, "lockdown_connect");
            void (*lockdown_disconnect)(LockdownConnectionRef) = (void (*)(LockdownConnectionRef))dlsym(handle, "lockdown_disconnect");
            CFPropertyListRef (*lockdown_copy_value)(LockdownConnectionRef, CFStringRef, CFStringRef) = (CFPropertyListRef (*)(LockdownConnectionRef, CFStringRef, CFStringRef))dlsym(handle, "lockdown_copy_value");

            if ((kLockdownUniqueDeviceIDKey != NULL) &&
                    (lockdown_connect != NULL) &&
                    (lockdown_copy_value != NULL) &&
                    (lockdown_disconnect != NULL)
               ) {
                LockdownConnectionRef lockdown = lockdown_connect();
                if (lockdown != NULL) {
                    value = (CFStringRef)lockdown_copy_value(lockdown, NULL, *kLockdownUniqueDeviceIDKey);
                    lockdown_disconnect(lockdown);
                }
            }
            dlclose(handle);
        }
    } else {
        // NOTE: Can't link to dylib as it doesn't exist in older iOS versions.
        void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
        if (handle != NULL) {
            CFPropertyListRef (*MGCopyAnswer)(CFStringRef) = (CFPropertyListRef (*)(CFStringRef))dlsym(handle, "MGCopyAnswer");
            if (MGCopyAnswer != NULL) {
                value = MGCopyAnswer(CFSTR("UniqueDeviceID"));
            }
            dlclose(handle);
        }
    }

    if (value != NULL) {
        if (CFGetTypeID(value) == CFStringGetTypeID()) {
            ret = [NSString stringWithString:(NSString *)value];
        }
        CFRelease(value);
    }

    return ret;
}

/* vim: set ft=c ff=unix sw=4 ts=4 expandtab tw=80: */
