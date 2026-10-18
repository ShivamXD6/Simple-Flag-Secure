LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := simple_flag_secure
LOCAL_SRC_FILES := module.cpp binder.cpp
LOCAL_LDLIBS := -llog -ldl
LOCAL_CPPFLAGS := -std=c++20 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fvisibility=hidden -fvisibility-inlines-hidden -Oz
LOCAL_LDFLAGS := -Wl,--gc-sections -Wl,--exclude-libs,ALL
include $(BUILD_SHARED_LIBRARY)
