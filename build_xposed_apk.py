#!/usr/bin/env python3
import os
import sys
import shutil
import zipfile
import subprocess

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
MODULE_DIR = os.path.join(PROJECT_ROOT, "xposed_module")
SRC_DIR = os.path.join(MODULE_DIR, "src")
RES_DIR = os.path.join(MODULE_DIR, "res")
ASSETS_DIR = os.path.join(MODULE_DIR, "assets")
LIBS_DIR = os.path.join(MODULE_DIR, "libs")
MANIFEST = os.path.join(MODULE_DIR, "AndroidManifest.xml")

BUILD_DIR = os.path.join(MODULE_DIR, "build")
BIN_DIR = os.path.join(BUILD_DIR, "bin")
DEX_DIR = os.path.join(BUILD_DIR, "dex")

OUTPUT_APK = os.path.join(PROJECT_ROOT, "Simple_Flag_Secure_LSPatch_v10.1.apk")
KEYSTORE = os.path.join(PROJECT_ROOT, "debug.keystore")

# Android SDK Detection
SDK_ROOT = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
if not SDK_ROOT:
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    default_sdk = os.path.join(local_app_data, "Android", "Sdk")
    if os.path.exists(default_sdk):
        SDK_ROOT = default_sdk

if not SDK_ROOT:
    sys.exit("Error: ANDROID_HOME or Android SDK not found.")

BUILD_TOOLS_DIR = os.path.join(SDK_ROOT, "build-tools")
versions = sorted(os.listdir(BUILD_TOOLS_DIR), reverse=True)
if not versions:
    sys.exit("Error: No build-tools found.")
BUILD_TOOLS = os.path.join(BUILD_TOOLS_DIR, versions[0])

AAPT2 = os.path.join(BUILD_TOOLS, "aapt2.exe" if sys.platform == "win32" else "aapt2")
D8 = os.path.join(BUILD_TOOLS, "d8.bat" if sys.platform == "win32" else "d8")
ZIPALIGN = os.path.join(BUILD_TOOLS, "zipalign.exe" if sys.platform == "win32" else "zipalign")
APKSIGNER = os.path.join(BUILD_TOOLS, "apksigner.bat" if sys.platform == "win32" else "apksigner")

PLATFORMS_DIR = os.path.join(SDK_ROOT, "platforms")
plat_versions = sorted([p for p in os.listdir(PLATFORMS_DIR) if os.path.exists(os.path.join(PLATFORMS_DIR, p, "android.jar"))], reverse=True)
if not plat_versions:
    sys.exit("Error: No valid android.jar found in platforms.")
ANDROID_JAR = os.path.join(PLATFORMS_DIR, plat_versions[0], "android.jar")
XPOSED_API_JAR = os.path.join(LIBS_DIR, "api-82.jar")

def clean_build():
    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BIN_DIR, exist_ok=True)
    os.makedirs(DEX_DIR, exist_ok=True)

def compile_resources():
    print("Compiling resources with aapt2...")
    compiled_res = os.path.join(BUILD_DIR, "compiled_res.zip")
    subprocess.run([AAPT2, "compile", "--dir", RES_DIR, "-o", compiled_res], check=True)
    
    print("Linking APK with aapt2...")
    unaligned_apk = os.path.join(BUILD_DIR, "base.apk")
    cmd = [
        AAPT2, "link",
        "-I", ANDROID_JAR,
        "--manifest", MANIFEST,
        "-o", unaligned_apk,
        compiled_res,
        "--auto-add-overlay"
    ]
    subprocess.run(cmd, check=True)
    return unaligned_apk

def compile_java():
    print("Compiling Java source files...")
    java_files = []
    for root, _, files in os.walk(SRC_DIR):
        for f in files:
            if f.endswith(".java"):
                java_files.append(os.path.join(root, f))
    
    cp_sep = ";" if sys.platform == "win32" else ":"
    classpath = f"{ANDROID_JAR}{cp_sep}{XPOSED_API_JAR}"
    
    cmd = [
        "javac",
        "-encoding", "UTF-8",
        "-cp", classpath,
        "-d", BIN_DIR,
        "--release", "11"
    ] + java_files
    subprocess.run(cmd, check=True)

def generate_dex():
    print("Converting class files to DEX with d8...")
    class_files = []
    for root, _, files in os.walk(BIN_DIR):
        for f in files:
            if f.endswith(".class"):
                class_files.append(os.path.join(root, f))
                
    cmd = [
        D8,
        "--min-api", "26",
        "--output", DEX_DIR
    ] + class_files
    subprocess.run(cmd, shell=(sys.platform == "win32"), check=True)

def package_apk(base_apk):
    print("Packaging classes.dex and assets into APK...")
    packaged_apk = os.path.join(BUILD_DIR, "packaged.apk")
    shutil.copyfile(base_apk, packaged_apk)
    
    with zipfile.ZipFile(packaged_apk, "a") as z:
        # Add DEX files stored uncompressed for direct memory mapping and LSPatch SharedMemory compatibility
        for f in os.listdir(DEX_DIR):
            if f.endswith(".dex"):
                z.write(os.path.join(DEX_DIR, f), f, compress_type=zipfile.ZIP_STORED)
                print(f"  added (stored): {f}")
        
        # Add assets
        for root, _, files in os.walk(ASSETS_DIR):
            for f in files:
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, MODULE_DIR)
                z.write(full_path, rel_path.replace("\\", "/"), compress_type=zipfile.ZIP_STORED)
                print(f"  added (stored): {rel_path}")
                
    return packaged_apk

def ensure_keystore():
    if not os.path.exists(KEYSTORE):
        print("Generating debug keystore...")
        cmd = [
            "keytool",
            "-genkeypair",
            "-v",
            "-keystore", KEYSTORE,
            "-storepass", "android",
            "-alias", "androiddebugkey",
            "-keypass", "android",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Android Debug,O=Android,C=US"
        ]
        subprocess.run(cmd, check=True)

def sign_and_align(packaged_apk):
    print("Aligning APK with zipalign...")
    aligned_apk = os.path.join(BUILD_DIR, "aligned.apk")
    subprocess.run([ZIPALIGN, "-f", "-p", "4", packaged_apk, aligned_apk], check=True)
    
    print("Signing APK with apksigner...")
    ensure_keystore()
    
    cmd = [
        APKSIGNER,
        "sign",
        "--v1-signing-enabled", "true",
        "--v2-signing-enabled", "true",
        "--v3-signing-enabled", "true",
        "--ks", KEYSTORE,
        "--ks-pass", "pass:android",
        "--ks-key-alias", "androiddebugkey",
        "--key-pass", "pass:android",
        "--out", OUTPUT_APK,
        aligned_apk
    ]
    subprocess.run(cmd, shell=(sys.platform == "win32"), check=True)
    
    size_kb = os.path.getsize(OUTPUT_APK) / 1024
    print(f"\n[SUCCESS] Built: {os.path.basename(OUTPUT_APK)} ({size_kb:.1f} KB)")

if __name__ == "__main__":
    clean_build()
    base_apk = compile_resources()
    compile_java()
    generate_dex()
    packaged = package_apk(base_apk)
    sign_and_align(packaged)
