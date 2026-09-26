# Simple Flag Secure

> 👀 Lightweight root module that disables FLAG_SECURE, enabling screenshots & screen recording in restricted apps. Hides screenshot detection on Android 14+. Includes a toggleable privacy mode to block screenshots system-wide. Supports Magisk, KernelSU, APatch & forks with no extra dependencies.

[![Downloads](https://img.shields.io/github/downloads/ShivamXD6/Simple-Flag-Secure/total?color=green&style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Release](https://img.shields.io/github/v/release/ShivamXD6/Simple-Flag-Secure?style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Join Build Bytes](https://img.shields.io/badge/Join-Build%20Bytes-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytes)
[![Join Chat](https://img.shields.io/badge/Join%20Chat-Build%20Bytes%20Discussion-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytesDiscussion)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Root](https://img.shields.io/badge/Root-ff0000?style=for-the-badge&logo=superuser&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-000000?style=for-the-badge&logo=linux&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-FF6B00?style=for-the-badge&logo=android&logoColor=white)

## ❔ Why Simple Flag Secure?

You may be wondering: **Why use this when other FLAG_SECURE modules (dependent on Zygisk / LSPosed) already exists?**

Simple Flag Secure focuses on being lightweight, maintainable, and compatible with newer Android versions and root solutions.

- 🛠️ **No Zygisk or LSPosed Required** — 100% standalone, no extra frameworks or meta-modules needed.
- 🪶 **Ultra-Compact (286 KB)** — Shrunk by 75% with zero bloat; patcher runs once and cleans up immediately.
- 🔋 **Zero Battery Drain & RAM Friendly** — Patched once at install time; zero background services or daemons running.
- 🚫 **Screenshot Detection Blocking** — Prevents apps from detecting screenshots (WhatsApp, Snapchat, etc. on Android 14+).
- 🔕 **Suppresses Screen Share Warnings** — Hides the irritating *"App content hidden from screen share"* popup on Android 15/16.
- 🎛️ **Interactive Volume Key Menu** — Switch between ALLOWED and BLOCKED (`[Vol +]`) or run live diagnostics (`[Vol -]`) without rebooting.
- 🩺 **Built-in Auto Diagnostics** — Saves diagnostic logs (`sfs_debug.log`) & `services.jar` directly to your Downloads folder.
- ⭐ **Modern Root Manager Support** — Works seamlessly with Magisk, KernelSU, APatch, and forks.
- 🔄 **In-App Manager Updates** — Native one-click updates directly inside root managers via `updateJson`.
- 📱 **Broad OEM Compatibility** — Full support for HyperOS, MIUI, OxygenOS, ColorOS, Realme UI, and One UI.

### 📊 How Does Simple Flag Secure Compare?

| Feature | **Simple Flag Secure** | **ih8SecureLock** | **DisableFlagSecure** |
| :--- | :---: | :---: | :---: |
| **Architecture** | **System Framework Patch** (`services.jar`) | Zygisk In-Process Hook (`.so`) | Xposed In-Process Hook (LSPosed) |
| **Dependencies** | **None (Standalone)** | Requires Zygisk / ZygiskNext | Requires LSPosed + Zygisk |
| **Works with Banking Apps / Denylist** | ✅ **100% Compatible** | ❌ **Broken on Denylist** *(stops working if unmount/hide root is active)* | ⚠️ **Fails or triggers root detection** |
| **Client App Tamper Detection** | 🛡️ **Zero (Undetectable)** | ⚠️ High (Foreign `.so` injected into app memory) | ❌ High (Xposed hooks easily flagged by banks) |
| **Battery & CPU Overhead** | 🔋 **0% (Zero drain)** | ⚠️ In-memory hook overhead | ❌ High drain (Xposed daemon + bridge) |
| **Runtime RAM Usage** | ⚡ **0 MB (No background processes)** | Persistent memory overhead per app | Heavy (~50MB+ for LSPosed daemon) |
| **Hides Screenshot Alerts (Android 14+)** | ✅ **Built-in System-wide** | ⚠️ Only for hooked apps | ❌ Not supported |
| **Dynamic Privacy Mode (Block / Allow)** | ✅ **Interactive Vol Key Toggle** | ❌ None | ❌ None |
| **Supported Root Managers** | Magisk, KernelSU, APatch | Magisk, KernelSU | Magisk, KernelSU (via LSPosed) |

#### 💡 Why Standalone Framework Patching is Better:
1. **Works with Banking Apps & Denylist:**
   Zygisk and LSPosed modules inject code into apps. When you hide root from banking apps using Magisk/KernelSU's **Denylist** (Unmount Modules), Zygisk and LSPosed are disabled — breaking screenshots for the apps where you need them most! Simple Flag Secure patches the Android system itself, so screenshots work everywhere even with full root hiding enabled.
2. **Zero Detection by Apps:**
   Restricted apps are never modified or injected with foreign code. Banking and streaming apps cannot detect that screenshots are unlocked.
3. **Zero Battery Drain:**
   No background services, hook bridges, or daemons running. Simple Flag Secure patches once during install and leaves behind 0 MB RAM usage and 0% battery drain.


## 📥 Installation

Removing screenshot restrictions is straightforward:

1. **Install the Module**
   Open your Magisk, KernelSU, or APatch manager → **Modules** → **Install from storage** → Select the **Simple Flag Secure** ZIP.

2. **Automatic Installation Logs**
   Installation logs are **automatically saved** to `/sdcard/Download/sfs_install.log` (and inside the module folder). No need to manually press the save button!

3. **Reboot**
   Restart your device to apply the changes.

4. **Test**
   Try taking a screenshot or recording your screen in an app that normally blocks it, such as a WhatsApp profile picture or Chrome Incognito.

## 🧰 Troubleshooting

### 🔄 Bootloop / System Doesn't Boot

If the module causes a bootloop or prevents Android from starting:

1. Reboot into **Recovery** (TWRP or another recovery).
2. Navigate to:
   `/data/adb/modules/simple_flag_secure`
3. Delete the `simple_flag_secure` directory.
4. Reboot into System.
5. Report the issue in the **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)** group.

### 🚫 Module Doesn't Work / Need Help?

Taking diagnostic logs is now super easy directly from your root manager:

1. Tap the **Action** button in Magisk, KernelSU, or APatch (or run `su -c "sh /data/adb/modules/simple_flag_secure/action.sh record"` in Termux).
2. Press **Volume Down [Vol -]** within 10 seconds to start the live recording session.
3. Switch to your restricted app and try taking a screenshot.
4. Press **ANY hardware button** (Volume Up, Volume Down, or Power) — recording stops instantly with 0ms delay!
5. Both `sfs_debug.log` and your system's `services.jar` are automatically saved to your **`Downloads`** folder (`/sdcard/Download/`), and Telegram opens directly to **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)**.
6. Share **BOTH** files (`sfs_debug.log` & `services.jar`) in the group for instant help!

## 🙏 Support & Donations

If you find Simple Flag Secure useful and would like to support its development:

- 💲 **Bhim (International UPI):** UPI ID - `shivamdhage@upi` | [Donate via QR](https://i.ibb.co/ZRm2xN2L/bhimupi.jpg)
- 💵 **GPay / UPI:** UPI ID - `shivamashokdhage6@oksbi` | [Donate via QR](https://i.ibb.co/5g4J2RXR/1f38d6d7-a8a2-4696-88e6-9cf503e0592c.png)
- 💰 **PayPal:** Username - `ShivamXD6` [Donate via PayPal](https://www.paypal.com/paypalme/ShivamXD6)

Your support helps keep the project maintained and improve compatibility with newer Android versions.

## 🙌 Credits

- **[ShirigiriPatil](https://telegram.me/BosadBillaHun)**
  Tested the module on KernelSU.

- **[LazyMeao](https://telegram.me/lazymeao)** & [@Black_luciferS](https://github.com/Blacklucifer82)
  Tested the module on Realme UI 2.0 for compatibility and Toggle Action of Block / Unblock.

- **[ShishirThakur](https://telegram.me/Shishirsthakur)**
  Tested screenshot detection functionality on Android 14+.

- **[Marmot](https://telegram.me/aptgo)**
  Tested the module on MIUI Android 11 using SukiSU, a KernelSU fork, helping verify compatibility and stability.

- **[@nyxnrv](https://github.com/777kzn)**
  Tested the module on HyperOS Android 17 Kernel SU.

- **[@Vikrant_R_Rajput](https://telegram.me/DeskAestheticx)**
  Tested the module on Samsung's OneUI Port Magisk.

- **[@idral](https://telegram.me/DeskAestheticx/@idral)**
  Tested the module without MetaModule for standalone mounting test.
