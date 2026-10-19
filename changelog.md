# 👀 Simple Flag Secure v11 (Standalone Edition) — True Standalone & Stealth Mount Release

> [!NOTE]
> This release focuses specifically on the **Standalone Edition** (`Simple_Flag_Secure_v11.zip`), introducing a 100% true standalone mounting architecture with zero root-token stealth staging. The Zygisk and Non-Root (LSPatch) editions remain on v10.0.

---

### 🛡️ What's New in v11 (Standalone)
- 🛠️ **100% Standalone (No Meta-Modules Needed)**:
  - Removed all dependencies on meta-modules (like NoMount or Hybrid Mount) and Magisk Magic Mount.
  - SFS is now completely self-mounting out of the box across Magisk, KernelSU, and APatch.
- 🥷 **Completely Leak-Free**:
  - Built-in stealth mounting leaves zero root traces behind.
  - Detectors (like Duck Detector) and sensitive banking apps can no longer spot root mount artifacts.
- 🔄 **Cleaner Codebase**:
  - Removed redundant SUSFS binary calls and obsolete checks for a faster, cleaner boot.
- 📱 **Android 15 / 16 Stability**:
  - Fixed soft-reboot and bootloop issues across Android 15 & 16 (OxygenOS, ColorOS, HyperOS).
- ⚡ **KernelSU Auto-Umount**:
  - Automatically isolates the mount from untrusted non-root apps.

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
