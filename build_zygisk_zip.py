#!/usr/bin/env python3
import os
import sys
import subprocess
import zipfile

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

NDK_BUILD = r"C:\Users\Shivam\AppData\Local\Android\Sdk\ndk\29.0.14206865\ndk-build.cmd"
LLVM_STRIP = r"C:\Users\Shivam\AppData\Local\Android\Sdk\ndk\29.0.14206865\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-strip.exe"

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
ZYGISK_SRC = os.path.join(PROJECT_ROOT, "zygisk_src")
LIBS_DIR = os.path.join(ZYGISK_SRC, "libs")
OUTPUT_ZIP = os.path.join(PROJECT_ROOT, "Simple_Flag_Secure_Zygisk_v10.0.zip")

def build_native():
    print("Compiling Zygisk C++ shared libraries with ndk-build...")
    cmd = [
        NDK_BUILD,
        f"NDK_PROJECT_PATH={ZYGISK_SRC}",
        f"APP_BUILD_SCRIPT={os.path.join(ZYGISK_SRC, 'jni', 'Android.mk')}",
        f"NDK_APPLICATION_MK={os.path.join(ZYGISK_SRC, 'jni', 'Application.mk')}",
        "-j8"
    ]
    subprocess.run(cmd, check=True)
    
    print("Stripping symbols with llvm-strip...")
    for root, _, files in os.walk(LIBS_DIR):
        for f in files:
            if f.endswith(".so"):
                so_path = os.path.join(root, f)
                subprocess.run([LLVM_STRIP, "--strip-all", so_path], check=True)

def create_zip():
    print(f"Packaging {os.path.basename(OUTPUT_ZIP)}...")
    
    abis = {
        "arm64-v8a": os.path.join(LIBS_DIR, "arm64-v8a", "libsimple_flag_secure.so"),
        "armeabi-v7a": os.path.join(LIBS_DIR, "armeabi-v7a", "libsimple_flag_secure.so"),
    }
    
    with zipfile.ZipFile(OUTPUT_ZIP, "w", compression=zipfile.ZIP_DEFLATED) as z:
        # Standard Magisk / KSU installer binaries
        z.write(os.path.join(PROJECT_ROOT, "META-INF", "com", "google", "android", "update-binary"),
                "META-INF/com/google/android/update-binary")
        z.write(os.path.join(PROJECT_ROOT, "META-INF", "com", "google", "android", "updater-script"),
                "META-INF/com/google/android/updater-script")
        
        # Module metadata
        for fname in ["module.prop", "customize.sh", "action.sh"]:
            fpath = os.path.join(PROJECT_ROOT, "zygisk_module", fname)
            with open(fpath, "rb") as f:
                content = f.read().replace(b"\r\n", b"\n")
            z.writestr(fname, content)
        
        # Zygisk binaries
        for abi_name, so_path in abis.items():
            if os.path.exists(so_path):
                arcname = f"zygisk/{abi_name}.so"
                z.write(so_path, arcname)
                print(f"  added: {arcname} ({os.path.getsize(so_path) // 1024} KB)")

    size_mb = os.path.getsize(OUTPUT_ZIP) / (1024 * 1024)
    print(f"Successfully built {os.path.basename(OUTPUT_ZIP)} ({size_mb:.2f} MB)!")

if __name__ == "__main__":
    os.makedirs(os.path.join(PROJECT_ROOT, "zygisk_module"), exist_ok=True)
    build_native()
    create_zip()
