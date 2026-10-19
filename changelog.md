# 👀 Simple Flag Secure v10.1 — Universal Update

> [!NOTE]
> This release updates **all three variants** (Standalone, Zygisk, and LSPatch/LSPosed) to **v10.1**, bringing universal mounting resilience, interactive setup guidance, and an official app icon!

---

### 🛡️ What's New in v10.1 — Standalone Edition (`Simple_Flag_Secure_v10.1.zip`)

- 🛠️ **Two-Tier Universal Mounting Strategy**:
  - **Tier 1 (Stealth In-Memory Staging)**: On supported devices (OnePlus, Pixel, Xiaomi, Motorola, Nothing, etc.), SFS stages the patched `services.jar` in memory (`/dev`), eliminating all `/data/adb/` root tokens from `/proc/self/mountinfo` for stealth anti-detection against Duck Detector and banking apps.
  - **Tier 2 (Direct Bind Mount Fallback)**: On strict vendor ROMs like Samsung Knox / One UI that block bind-mounting from memory (`devtmpfs`), SFS detects the block and instantly falls back to direct bind mounting. Fixes the `Mount mismatch / services.jar not mounted` failure reported on Samsung Galaxy S25 / Android 16!
- 🥷 **KernelSU & SusFS Stealth Integration**:
  - Automatically registers `ksud kernel umount add` to unmount `services.jar` from non-root processes.
  - Automatically detects and hooks `ksu_susfs` (if installed on KernelSU or APatch) to register `add_sus_path`, `hide_sus_mnts_for_non_su_procs 1`, and `add_try_umount` for seamless mount hiding.
- 🚫 **Zero Meta-Module Dependency**:
  - 100% self-sufficient out of the box—no meta-modules (like NoMount or Hybrid Mount) required.
- 📱 **Android 15 & 16 Stability**:
  - Fully tested and stable on Android 15 & 16 across HyperOS, OxygenOS, ColorOS, and One UI.

---

### ⚡ What's New in v10.1 — Zygisk Edition (`Simple_Flag_Secure_Zygisk_v10.1.zip`)

- 💡 **Interactive Setup Guidance During Flashing**:
  - The installer now provides clear, concise setup tips directly in the manager console.
  - **Recommendation**: Highlights using **Zygisk Next** or **ReZygisk CI**, which hook apps properly even with app unmounting / hiding enabled.
  - **DenyList / Umount Clarification**:
    - _To screenshot an app_: If using standard Magisk Zygisk, remove the target app from DenyList (Magisk), Umount (KernelSU), or Exclude Modifications (APatch) so the in-app hook can load.
    - _To hide from banking apps_: Simply add them to DenyList / Umount / Exclude Modifications.
- 🔄 **In-App Manager Updates**:
  - Native `updateJson` configured for one-click updates directly inside Magisk, KernelSU, and APatch managers.
- 🪶 **RAM-Only Architecture**:
  - Retains zero disk modifications and ultra-compact ~19 KB footprint.

---

### 📱 What's New in v10.1 — Non-Root & LSPosed Edition (`Simple_Flag_Secure_LSPatch_v10.1.apk`)

- 🎨 **Official 👀 App Icon**:
  - Added a distinctive, modern app icon featuring the signature 👀 emoji on a dark slate background.
  - Fully supports modern Android **Adaptive Icons** (`mipmap-anydpi-v26`) as well as circular icons and legacy launcher mipmaps (`mdpi` up to `xxxhdpi`).
  - Displays beautifully inside LSPatch Manager, LSPosed Manager, and device application lists instead of a default placeholder.
- 🎯 **Preconfigured Default Scope**:
  - Added default Xposed scope metadata in `AndroidManifest.xml` targeting System Framework, WhatsApp, Snapchat, and Telegram for one-tap setup in LSPosed.
- 📦 **Dual Non-Root / Root Support**:
  - Works both standalone inside apps patched via **[JingMatrix LSPatch](https://github.com/JingMatrix/LSPatch)** without root, and as a standard Xposed module in **LSPosed** with root.

---

# 👀 Simple Flag Secure v10.0 — Unified Triple-Architecture Release

> [!NOTE]
> **Why jump to v10.0 (and where are v8 & v9)?**
> During development, **v8** was built as the Standalone/Meta-Module architecture rewrite and **v9** was the dedicated Zygisk native overhaul. To eliminate confusing separate release trees, avoid fragmentation from unstable beta builds, and celebrate the arrival of the 3rd architecture (LSPatch/LSPosed for Non-Root), all developments have converged into **v10.0**!

---

### 📱 [v10] Non-Root Edition (LSPatch & LSPosed APK)

- 🚀 **Works Without Root**: Take screenshots in restricted apps on unrooted phones by patching them with **[JingMatrix LSPatch](https://github.com/JingMatrix/LSPatch)**.
- 🧩 **LSPosed Compatible**: Also works directly as a standard module inside LSPosed if your device is rooted.
- 🔕 **Blocks Screenshot Alerts**: Stops apps (like WhatsApp, Snapchat) from notifying the sender or showing warning toasts when you take a screenshot.
- 🪶 **Super Small**: Just **~16.5 KB**.

---

### ⚡ [v9] Zygisk Edition (RAM-Only / In-Memory)

- 🥷 **Smart Per-App Hooking**:
  - Automatically bypasses restrictions inside apps while staying completely hidden.
  - If a stubborn app still blocks screenshots, simply turn off DenyList / Umount / Exclude Modifications for that app so the direct in-app hook attaches!
- ⚡ **Recommended Setup**: Works best with **Zygisk Next** or **ReZygisk** (fixes issues on Xiaomi, OnePlus, and Samsung ROMs).
- 🪶 **Zero File Changes**: Keeps your system 100% clean—nothing modified on disk. Download size is only **~19 KB**.

---

### 🛡️ [v8] Standalone Edition (No Zygisk Required)

- 🛠️ **100% Standalone**: Automatically patches screenshot restrictions on boot without needing Zygisk or Xposed.
- 📱 **OnePlus & Oppo Fix**: Fixed screenshot blocking on OnePlus (OxygenOS & ColorOS 14/15) so screenshots capture properly.
- 🔄 **Built-in Auto-Mount & Android 15 Stability**: Safe mounting without breaking Zygote namespaces or causing soft-reboot loops.
- 🥷 **Advanced Mount Hiding & Anti-Detection**:
  - **Ephemeral `tmpfs` Staging**: Eliminates `/adb/modules/` tokens and disk partition artifacts from `/proc/self/mountinfo`. Scanners like Duck Detector see only a clean `/services.jar` from `tmpfs`.
  - **KernelSU Auto-Umount Support**: Integrates with `ksud kernel umount` to automatically unmount the target for untrusted non-root apps.
  - **Meta-Module & NoMount Compatible**: Zero conflicts with NoMount or Meta-Modules.
- 🎛️ **Action Menu & Privacy Toggle**: Tap Action in your root manager and press **Volume Up** to toggle Privacy Mode (block screenshots everywhere) or **Volume Down** to save logs.
- 🪶 **Tiny Size**: Just **~172 KB**.

---

# 👀 Simple Flag Secure v7.7 - (_Thala for a Reason_)

- 🪶 **75% Smaller Size**: Shrunk from 1.1 MB down to just **286 KB** while keeping all features intact.
- 📱 **Fixed Xiaomi & POCO (HyperOS / MIUI)**: Fixed screenshot blocking and capture timeouts on HyperOS and MIUI.
- 🔕 **Removed Screen Share Warning**: Suppressed the annoying _"App content hidden from screen share for security"_ popup on Android 15/16.
- 🎛️ **Volume Key Action Menu**:
  - **[Vol +]**: Instantly toggle between **Allowed** and **Blocked** (Privacy Mode) without rebooting.
  - **[Vol -]**: Starts a live debug recording session with simple step-by-step guidance.
- ⚡ **Easy 1-Click Log Recording**: Press any button (Power or Volume) to finish recording. Both `sfs_debug.log` and `services.jar` are automatically saved to your **Downloads** folder.
- 🔋 **Zero Battery Drain**: 100% stock battery life with zero background services or daemons running.
- 🎨 **Cleaner System Icons**: Clean notifications with official system icons for Allowed, Blocked, and Saved states.
