/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, Version 2.0
 *          (See LICENSE file for details)
 */

#include "nslog_to_os_log.h"

struct os_log_s *_os_log_default = NULL;
bool (*os_log_type_enabled)(os_log_t oslog, os_log_type_t type) = NULL;
void (*_os_log_impl)(void *dso, os_log_t log, os_log_type_t type, const char *format, uint8_t *buf, unsigned int size) = NULL;

__attribute__((constructor)) static void init() {
    if (IOS_GTE(10_0)) {
        void *handle = dlopen("/usr/lib/libSystem.dylib", RTLD_LAZY | RTLD_NOLOAD);
        if (handle != NULL) {
            _os_log_default = (struct os_log_s *)dlsym(handle, "_os_log_default");
            os_log_type_enabled = (bool (*)(os_log_t, os_log_type_t))dlsym(handle, "os_log_type_enabled");
            _os_log_impl = (void (*)(void *, os_log_t, os_log_type_t, const char *, uint8_t *, unsigned int))dlsym(handle, "_os_log_impl");
            dlclose(handle);
        }
    }
}

/* vim: set ft=objc ff=unix sw=4 ts=4 expandtab tw=80: */
