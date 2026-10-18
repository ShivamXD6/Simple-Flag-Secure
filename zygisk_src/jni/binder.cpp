#include "binder.hpp"

#include <android/log.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <unistd.h>

#define LOGD(fmt, ...) \
    __android_log_print(ANDROID_LOG_DEBUG, "SimpleFlagSecure", "[%d] " fmt, __LINE__, ##__VA_ARGS__)

bool getMapping(const char* lib_name, ino_t* inode, dev_t* dev) {
    FILE* fp = fopen("/proc/self/maps", "r");
    if (!fp) return false;
    char mapbuf[512], flags[8];
    while (fgets(mapbuf, sizeof(mapbuf), fp)) {
        if (strstr(mapbuf, lib_name) == nullptr) continue;
        unsigned int dev_major = 0, dev_minor = 0;
        unsigned long ino = 0;
        if (sscanf(mapbuf, "%*s %7s %*x %x:%x %lu", flags, &dev_major, &dev_minor, &ino) == 4) {
            if (flags[2] == 'x') {
                *inode = (ino_t)ino;
                *dev = makedev(dev_major, dev_minor);
                fclose(fp);
                return true;
            }
        }
    }
    fclose(fp);
    return false;
}

uint32_t getStaticIntFieldJni(JNIEnv* env, const char* cls_name, const char* field_name) {
    jclass cls = env->FindClass(cls_name);
    if (cls == nullptr) {
        env->ExceptionClear();
        LOGD("Could not get class '%s'", cls_name);
        return 0;
    }
    jfieldID field = env->GetStaticFieldID(cls, field_name, "I");
    if (field == nullptr) {
        env->ExceptionClear();
        LOGD("Could not get field %s.%s", cls_name, field_name);
        return 0;
    }
    jint val = env->GetStaticIntField(cls, field);
    env->DeleteLocalRef(cls);
    return val;
}
