#include <android/api-level.h>
#include <android/log.h>
#include <dlfcn.h>
#include <jni.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include "binder.hpp"
#include "zygisk.hpp"

#define LOGI(fmt, ...) \
    __android_log_print(ANDROID_LOG_INFO, "SimpleFlagSecure", fmt, ##__VA_ARGS__)
#define LOGW(fmt, ...) \
    __android_log_print(ANDROID_LOG_WARN, "SimpleFlagSecure", fmt, ##__VA_ARGS__)

#define LAYER_SECURE 0x00000080
#define FLAG_SECURE  0x00002000

#define I_WINDOW_SESSION_DESC        u"android.view.IWindowSession"
#define I_ACTIVITY_TASKMANAGER_DESC  u"android.app.IActivityTaskManager"
#define I_WINDOW_MANAGER_DESC        u"android.view.IWindowManager"

static int sdk = 0;
static bool should_unload_app = false;

static uint32_t relayout_code = 0;
static uint32_t relayoutAsync_code = 0;
static uint32_t relayout2_code = 0;
static uint32_t relayoutAsync2_code = 0;
static uint32_t registerScreenCaptureObserver_code = 0;
static uint32_t registerScreenRecordingCallback_code = 0;
static uint32_t notifyScreenshotListeners_code = 0;

static inline bool isScreenshotAllowed() {
    char val[PROP_VALUE_MAX] = {0};
    if (__system_property_get("persist.wm.debug.sfs.screenshot", val) > 0 ||
        __system_property_get("persist.sys.sfs.screenshot", val) > 0) {
        return (strcmp(val, "false") != 0 && strcmp(val, "0") != 0);
    }
    return true;
}

static inline bool containsUtf16(const uint8_t* data, size_t size, const char16_t* needle, size_t needle_len) {
    if (size < needle_len * sizeof(char16_t)) return false;
    size_t limit = size - needle_len * sizeof(char16_t);
    if (limit > 512) limit = 512;
    for (size_t i = 0; i <= limit; i++) {
        if (memcmp(data + i, needle, needle_len * sizeof(char16_t)) == 0) {
            return true;
        }
    }
    return false;
}

// ---------------------------------------------------------------------------
// App-level (ih8SecureLock style for non-denylisted user apps)
// ---------------------------------------------------------------------------
static int (*appTransactOrig)(void*, int32_t, uint32_t, void*, void*, uint32_t) = nullptr;

static int appTransactHook(void* self, int32_t handle, uint32_t code, void* pdata, void* preply, uint32_t flags) {
    auto pparcel = (PParcel*)pdata;
    if (pparcel != nullptr && pparcel->data != nullptr && isScreenshotAllowed()) {
        auto parcel = FakeParcel(pparcel->data, pparcel->data_size);

        size_t binder_headers_len = getBinderHeadersLen(sdk);
        parcel.skip(binder_headers_len);

        auto descLen = parcel.readInt32();
        auto desc = parcel.readString16(descLen);
        if (desc != nullptr) {
            // 1. Strip FLAG_SECURE on window relayout
            if ((code == relayout_code || code == relayoutAsync_code ||
                 code == relayout2_code || code == relayoutAsync2_code) &&
                BINDER_DESC_CMP(I_WINDOW_SESSION_DESC, desc, descLen)) {
                parcel.skipFlatObj();
                if (sdk <= 30) parcel.skip(1 * sizeof(uint32_t));
                parcel.skip(4 * sizeof(uint32_t));
                parcel.skip(3 * sizeof(uint32_t));

                auto wflags = parcel.peekInt32Ref();
                if (wflags != nullptr && (*wflags & FLAG_SECURE)) {
                    *wflags &= ~FLAG_SECURE;
                    LOGI("[App] Bypassed FLAG_SECURE on LayoutParams");
                }
            }
            // 2. Neutralize screenshot detection registration (A14+)
            else if (code == registerScreenCaptureObserver_code &&
                     BINDER_DESC_CMP(I_ACTIVITY_TASKMANAGER_DESC, desc, descLen)) {
                LOGI("[App] Neutralized registerScreenCaptureObserver registration");
                return 0;
            }
            // 3. Neutralize screen recording detection registration (A15+)
            else if (code == registerScreenRecordingCallback_code &&
                     BINDER_DESC_CMP(I_WINDOW_MANAGER_DESC, desc, descLen)) {
                LOGI("[App] Neutralized registerScreenRecordingCallback registration");
                return 0;
            }
        }
    }
    return appTransactOrig(self, handle, code, pdata, preply, flags);
}

// ---------------------------------------------------------------------------
// Global / system_server (for ALL apps including denylisted/umounted ones)
// ---------------------------------------------------------------------------
typedef void (*nativeSetFlags_t)(JNIEnv* env, jclass clazz, jlong transactionObj, jlong nativeObject, jint flags, jint mask);
static nativeSetFlags_t orig_nativeSetFlags = nullptr;

static void hook_nativeSetFlags(JNIEnv* env, jclass clazz, jlong transactionObj, jlong nativeObject, jint flags, jint mask) {
    if (mask & LAYER_SECURE) {
        if (isScreenshotAllowed()) {
            flags &= ~LAYER_SECURE;
            LOGI("[system_server] Updated layer flags (active)");
        } else {
            flags |= LAYER_SECURE;
            LOGI("[system_server] Updated layer flags (restricted)");
        }
    }
    if (orig_nativeSetFlags != nullptr) {
        orig_nativeSetFlags(env, clazz, transactionObj, nativeObject, flags, mask);
    }
}

typedef void* (*Transaction_setFlags_t)(void* self, void* sc, uint32_t flags, uint32_t mask);
static Transaction_setFlags_t orig_transaction_setFlags = nullptr;

static void* hook_transaction_setFlags(void* self, void* sc, uint32_t flags, uint32_t mask) {
    if (mask & LAYER_SECURE) {
        if (isScreenshotAllowed()) {
            flags &= ~LAYER_SECURE;
            LOGI("[system_server] Updated transaction flags (active)");
        } else {
            flags |= LAYER_SECURE;
            LOGI("[system_server] Updated transaction flags (restricted)");
        }
    }
    if (orig_transaction_setFlags != nullptr) {
        return orig_transaction_setFlags(self, sc, flags, mask);
    }
    return self;
}

typedef int32_t (*JavaBBinder_onTransact_t)(void* self, uint32_t code, const void* data, void* reply, uint32_t flags);
static JavaBBinder_onTransact_t orig_JavaBBinder_onTransact = nullptr;

typedef jboolean (*BinderProxy_transact_t)(JNIEnv* env, jobject obj, jint code, jobject parcelObj, jobject replyObj, jint flags);
static BinderProxy_transact_t orig_BinderProxy_transact = nullptr;
static jfieldID gParcelNativePtrField = nullptr;

typedef const uint8_t* (*Parcel_data_t)(const void* self);
typedef size_t (*Parcel_dataSize_t)(const void* self);
typedef int32_t (*Parcel_writeInt32_t)(void* self, int32_t val);

static Parcel_data_t parcel_data = nullptr;
static Parcel_dataSize_t parcel_dataSize = nullptr;
static Parcel_writeInt32_t parcel_writeInt32 = nullptr;

static int32_t hook_JavaBBinder_onTransact(void* self, uint32_t code, const void* data, void* reply, uint32_t flags) {
    if (isScreenshotAllowed() && data != nullptr && parcel_data != nullptr && parcel_dataSize != nullptr) {
        const uint8_t* raw = parcel_data(data);
        size_t size = parcel_dataSize(data);

        if ((code == 0x95 || code == notifyScreenshotListeners_code) &&
            containsUtf16(raw, size, u"IWindowManager", 14)) {
            if (reply != nullptr && parcel_writeInt32 != nullptr) {
                parcel_writeInt32(reply, 0);
                parcel_writeInt32(reply, 0);
            }
            LOGI("[system_server] Filtered notifyScreenshotListeners");
            return 0;
        } else if ((code == 0x65 || code == registerScreenCaptureObserver_code || containsUtf16(raw, size, u"IScreenCaptureObserver", 22)) &&
                   containsUtf16(raw, size, u"IActivityTaskManager", 20)) {
            if (reply != nullptr && parcel_writeInt32 != nullptr) {
                parcel_writeInt32(reply, 0);
            }
            LOGI("[system_server] Filtered observer registration");
            return 0;
        } else if ((code == 0x9b || code == registerScreenRecordingCallback_code || containsUtf16(raw, size, u"IScreenRecordingCallback", 24)) &&
                   containsUtf16(raw, size, u"IWindowManager", 14)) {
            if (reply != nullptr && parcel_writeInt32 != nullptr) {
                parcel_writeInt32(reply, 0);
                parcel_writeInt32(reply, 0);
            }
            LOGI("[system_server] Filtered callback registration");
            return 0;
        }
    }
    if (orig_JavaBBinder_onTransact != nullptr) {
        return orig_JavaBBinder_onTransact(self, code, data, reply, flags);
    }
    return 0;
}

static jboolean hook_BinderProxy_transact(JNIEnv* env, jobject obj, jint code, jobject parcelObj, jobject replyObj, jint flags) {
    if (isScreenshotAllowed() && parcelObj != nullptr && gParcelNativePtrField != nullptr &&
        parcel_data != nullptr && parcel_dataSize != nullptr) {
        jlong nativePtr = env->GetLongField(parcelObj, gParcelNativePtrField);
        if (nativePtr != 0) {
            const void* parcel = (const void*)nativePtr;
            const uint8_t* raw = parcel_data(parcel);
            size_t size = parcel_dataSize(parcel);
            if (containsUtf16(raw, size, u"IScreenCaptureObserver", 22)) {
                LOGI("[system_server] Filtered outgoing observer notification");
                return JNI_TRUE;
            }
        }
    }
    if (orig_BinderProxy_transact != nullptr) {
        return orig_BinderProxy_transact(env, obj, code, parcelObj, replyObj, flags);
    }
    return JNI_FALSE;
}

static void exemptHiddenApis(JNIEnv* env) {
    jclass vmRuntimeCls = env->FindClass("dalvik/system/VMRuntime");
    if (vmRuntimeCls != nullptr) {
        jmethodID getRuntime = env->GetStaticMethodID(vmRuntimeCls, "getRuntime", "()Ldalvik/system/VMRuntime;");
        jmethodID setHiddenApiExemptions = env->GetMethodID(vmRuntimeCls, "setHiddenApiExemptions", "([Ljava/lang/String;)V");
        if (getRuntime != nullptr && setHiddenApiExemptions != nullptr) {
            jobject runtime = env->CallStaticObjectMethod(vmRuntimeCls, getRuntime);
            jclass strCls = env->FindClass("java/lang/String");
            if (runtime != nullptr && strCls != nullptr) {
                jobjectArray arr = env->NewObjectArray(1, strCls, env->NewStringUTF("L"));
                if (arr != nullptr) {
                    env->CallVoidMethod(runtime, setHiddenApiExemptions, arr);
                    env->DeleteLocalRef(arr);
                }
                env->DeleteLocalRef(strCls);
            }
            if (runtime != nullptr) env->DeleteLocalRef(runtime);
        }
        env->DeleteLocalRef(vmRuntimeCls);
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        }
    }
}

static void resolveTransactionCodes(JNIEnv* env) {
    exemptHiddenApis(env);

    relayout_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowSession"), BINDER_TRSCTN("relayout"));
    relayoutAsync_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowSession"), BINDER_TRSCTN("relayoutAsync"));
    relayout2_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowSession"), BINDER_TRSCTN("relayout2"));
    relayoutAsync2_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowSession"), BINDER_TRSCTN("relayoutAsync2"));

    registerScreenCaptureObserver_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/app/IActivityTaskManager"), BINDER_TRSCTN("registerScreenCaptureObserver"));
    if (registerScreenCaptureObserver_code == 0) {
        registerScreenCaptureObserver_code = 0x65;
    }
    registerScreenRecordingCallback_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowManager"), BINDER_TRSCTN("registerScreenRecordingCallback"));
    if (registerScreenRecordingCallback_code == 0) {
        registerScreenRecordingCallback_code = 0x9b;
    }
    notifyScreenshotListeners_code = getStaticIntFieldJni(
        env, BINDER_STUB("android/view/IWindowManager"), BINDER_TRSCTN("notifyScreenshotListeners"));
    if (notifyScreenshotListeners_code == 0) {
        notifyScreenshotListeners_code = 0x95;
    }
}

class SimpleFlagSecureZygisk : public zygisk::ModuleBase {
   public:
    void onLoad(zygisk::Api* api, JNIEnv* env) override {
        this->api = api;
        this->env = env;
    }

    void preAppSpecialize(zygisk::AppSpecializeArgs* args) override {
        should_unload_app = false;

        // 1. Process on Denylist / umount list -> unload immediately for 0% detection footprint
        if (api->getFlags() & zygisk::StateFlag::PROCESS_ON_DENYLIST) {
            should_unload_app = true;
            api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        // 2. System daemons / framework services (UID < 10000) -> unload immediately
        if (args->uid < 10000) {
            should_unload_app = true;
            api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        // 3. SystemUI -> unload to prevent any UI interference
        bool is_system_ui = false;
        if (args->nice_name != nullptr) {
            const char* name = env->GetStringUTFChars(args->nice_name, nullptr);
            if (name != nullptr) {
                if (strncmp(name, "com.android.systemui", 20) == 0) {
                    is_system_ui = true;
                }
                env->ReleaseStringUTFChars(args->nice_name, name);
            }
        }
        if (!is_system_ui && args->app_data_dir != nullptr) {
            const char* dir = env->GetStringUTFChars(args->app_data_dir, nullptr);
            if (dir != nullptr) {
                if (strstr(dir, "com.android.systemui") != nullptr) {
                    is_system_ui = true;
                }
                env->ReleaseStringUTFChars(args->app_data_dir, dir);
            }
        }
        if (is_system_ui) {
            should_unload_app = true;
            api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        // For all non-denylisted user apps: keep loaded for per-app FLAG_SECURE bypass & anti-detection
    }

    void postAppSpecialize(const zygisk::AppSpecializeArgs* args) override {
        (void)args;
        if (should_unload_app) {
            return;
        }

        sdk = android_get_device_api_level();
        resolveTransactionCodes(env);

        ino_t inode;
        dev_t dev;
        if (getMapping("libbinder.so", &inode, &dev)) {
            api->pltHookRegister(dev, inode,
                                 "_ZN7android14IPCThreadState8transactEijRKNS_6ParcelEPS1_j",
                                 (void**)&appTransactHook, (void**)&appTransactOrig);
            api->pltHookCommit();
            LOGI("[App] Initialized app-level transact hook");
        }
    }

    void preServerSpecialize(zygisk::ServerSpecializeArgs* args) override {
        (void)args;
    }

    void postServerSpecialize(const zygisk::ServerSpecializeArgs* args) override {
        (void)args;
        LOGI("[system_server] Initializing runtime controller");
        __system_property_set("debug.sfs.zygisk.active", "1");

        sdk = android_get_device_api_level();
        resolveTransactionCodes(env);

        JNINativeMethod methods[] = {
            {"nativeSetFlags", "(JJII)V", (void*)hook_nativeSetFlags}
        };
        api->hookJniNativeMethods(env, "android/view/SurfaceControl", methods, 1);
        if (methods[0].fnPtr != nullptr) {
            orig_nativeSetFlags = (nativeSetFlags_t)methods[0].fnPtr;
            LOGI("[system_server] Initialized component dispatch");
        } else {
            LOGW("[system_server] Component dispatch unavailable");
        }

        ino_t inode;
        dev_t dev;
        if (getMapping("libandroid_runtime.so", &inode, &dev)) {
            api->pltHookRegister(dev, inode,
                                 "_ZN7android21SurfaceComposerClient11Transaction8setFlagsERKNS_2spINS_14SurfaceControlEEEjj",
                                 (void**)&hook_transaction_setFlags, (void**)&orig_transaction_setFlags);
            api->pltHookCommit();
        }

        void* handle_binder = dlopen("libbinder.so", RTLD_NOLOAD);
        if (!handle_binder) handle_binder = dlopen("libbinder.so", RTLD_NOW);

        void* handle_runtime = dlopen("libandroid_runtime.so", RTLD_NOLOAD);
        if (!handle_runtime) handle_runtime = dlopen("libandroid_runtime.so", RTLD_NOW);

        if (handle_binder != nullptr) {
            parcel_data = (Parcel_data_t)dlsym(handle_binder, "_ZNK7android6Parcel4dataEv");
            parcel_dataSize = (Parcel_dataSize_t)dlsym(handle_binder, "_ZNK7android6Parcel8dataSizeEv");
            parcel_writeInt32 = (Parcel_writeInt32_t)dlsym(handle_binder, "_ZN7android6Parcel10writeInt32Ei");
        }

        jclass parcelClass = env->FindClass("android/os/Parcel");
        if (parcelClass != nullptr) {
            gParcelNativePtrField = env->GetFieldID(parcelClass, "mNativePtr", "J");
            env->DeleteLocalRef(parcelClass);
            if (env->ExceptionCheck()) env->ExceptionClear();
        }

        JNINativeMethod proxyMethods[] = {
            {"transactNative", "(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z", (void*)hook_BinderProxy_transact}
        };
        api->hookJniNativeMethods(env, "android/os/BinderProxy", proxyMethods, 1);
        if (proxyMethods[0].fnPtr != nullptr) {
            orig_BinderProxy_transact = (BinderProxy_transact_t)proxyMethods[0].fnPtr;
            LOGI("[system_server] Initialized proxy dispatch");
        }

        if (handle_runtime != nullptr) {
            void** vtable = (void**)dlsym(handle_runtime, "_ZTV11JavaBBinder");
            if (vtable != nullptr) {
                int target_idx = -1;
                Dl_info info;
                if (dladdr(vtable[19], &info) && info.dli_fname != nullptr && strstr(info.dli_fname, "libandroid_runtime.so") != nullptr) {
                    target_idx = 19;
                } else {
                    for (int i = 16; i <= 24; i++) {
                        if (dladdr(vtable[i], &info) && info.dli_fname != nullptr && strstr(info.dli_fname, "libandroid_runtime.so") != nullptr) {
                            target_idx = i;
                        }
                    }
                }

                if (target_idx >= 0) {
                    long page_size = sysconf(_SC_PAGESIZE);
                    if (page_size <= 0) page_size = 4096;
                    uintptr_t addr = (uintptr_t)&vtable[target_idx];
                    uintptr_t page_start = addr & ~(page_size - 1);
                    mprotect((void*)page_start, page_size * 2, PROT_READ | PROT_WRITE);
                    orig_JavaBBinder_onTransact = (JavaBBinder_onTransact_t)vtable[target_idx];
                    vtable[target_idx] = (void*)hook_JavaBBinder_onTransact;
                    mprotect((void*)page_start, page_size * 2, PROT_READ);
                    LOGI("[system_server] Initialized service transaction filter");
                }
            }
        }
    }

   private:
    zygisk::Api* api;
    JNIEnv* env;
};

REGISTER_ZYGISK_MODULE(SimpleFlagSecureZygisk)
