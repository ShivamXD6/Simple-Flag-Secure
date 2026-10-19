# Simple Flag Secure

> 👀 Lightweight module that disables `FLAG_SECURE`, enabling screenshots & screen recording across restricted apps. Hides screenshot detection and suppresses screen share warnings. Includes a toggleable privacy mode to block screenshots system-wide. Available in **Standalone**, **Zygisk**, and **Non-Root (LSPatch)** editions.

[![Downloads](https://img.shields.io/github/downloads/ShivamXD6/Simple-Flag-Secure/total?color=green&style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Release](https://img.shields.io/github/v/release/ShivamXD6/Simple-Flag-Secure?style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Join Build Bytes](https://img.shields.io/badge/Join-Build%20Bytes-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytes)
[![Join Chat](https://img.shields.io/badge/Join%20Chat-Build%20Bytes%20Discussion-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytesDiscussion)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Root](https://img.shields.io/badge/Root-ff0000?style=for-the-badge&logo=superuser&logoColor=white)
![Non-Root](https://img.shields.io/badge/Non--Root-4285F4?style=for-the-badge&logo=android&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-000000?style=for-the-badge&logo=linux&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-FF6B00?style=for-the-badge&logo=android&logoColor=white)

---

## 📑 Table of Contents

- [✨ Features](#-features)
- [🏆 Why Simple Flag Secure?](#-why-simple-flag-secure)
- [🚀 Choose Your Variant](#-choose-your-variant)
- [📱 Non-Root Users: LSPatch Setup Guide](#-non-root-users-lspatch-setup-guide)
- [⚡ Rooted Users: Zygisk Edition Setup](#-rooted-users-zygisk-edition-setup)
- [🛡️ Rooted Users: Standalone Edition Setup](#-rooted-users-standalone-edition-setup)
- [🎛️ Privacy Mode (Instant Toggle)](#-privacy-mode-instant-toggle)
- [📥 Installation Summary](#-installation-summary)
- [📢 Future Updates & Support](#-important-note-for-future-updates--support)
- [🙏 Support & Donations](#-support--donations)
- [🙌 Credits](#-credits)

---

## ✨ Features

- 🚫 **Unlocks Screenshots & Screen Recordings Everywhere** — Captures restricted screens in banking apps, financial services, WhatsApp view-once media, profile photos, and incognito tabs.
- 🔕 **Screenshot Detection & Warning Blocking** — Prevents apps from detecting screenshots and suppresses all detection warnings or chat notifications (WhatsApp, Snapchat, etc.).
- 🔕 **Suppresses Screen Share Warnings** — Hides the irritating _"App content hidden from screen share"_ popup on Android 15/16.
- 🛠️ **No Root or Framework Required (LSPatch Edition)** — Non-root users can embed SFS directly into targeted APKs with zero root footprint.
- 🛠️ **No Zygisk or LSPosed Required (Standalone Edition)** — 100% standalone, zero extra frameworks or meta-modules needed.
- 🎛️ **Interactive Privacy Mode (Action & Volume Menu)** — Switch between ALLOWED and BLOCKED (`[Vol +]`) or run live diagnostics (`[Vol -]`) without rebooting.
- 🔋 **Zero Battery Drain & RAM Friendly** — Ultra-lightweight with zero background daemons or battery consumption.
- 🪶 **Ultra-Compact Footprint** — Down to just **~19 KB** (Zygisk), **~172 KB** (Standalone), and **~16.5 KB** (LSPatch APK) with zero bloat.
- 🩺 **Built-in Auto Diagnostics** — Saves unified diagnostic log (`sfs.log`) directly to your Downloads folder for 1-click troubleshooting.
- ⭐ **Modern Root Manager Support** — Works seamlessly with Magisk, KernelSU, APatch, and all their forks.
- 🔄 **In-App Manager Updates** — Native one-click updates directly inside root managers via `updateJson`.
- 📱 **Broad OEM & OS Compatibility** — Supports Android 8 through Android 16 on HyperOS, MIUI, OxygenOS, ColorOS, Realme UI, and One UI.

---

## 🏆 Why Simple Flag Secure?

How does Simple Flag Secure compare to tools like **LSPosed (Disable-FLAG_SECURE)** and **Zygisk ih8SecureLock**?

| Comparison                          | ⚡ Simple Flag Secure                         | 🔒 Zygisk ih8SecureLock               | 🧩 LSPosed                    |
| :---------------------------------- | :-------------------------------------------- | :------------------------------------ | :---------------------------- |
| **No Extra Framework Needed**       | ✅ Yes (Lightweight & clean)                  | ✅ Yes                                | ❌ Requires LSPosed framework |
| **Works with Unmount / DenyList**   | ✅ Yes (Screenshots work even with DenyList!) | ❌ No (Forces you to unmount apps)    | ❌ No                         |
| **Banking App Safe**                | ✅ Zero traces in protected apps              | ⚠️ Requires unmounting, exposing root | ❌ Easily detected            |
| **Screenshot Detection Blocking**   | ✅ Yes (Prevents alerts & toasts)             | ✅ Yes                                | ⚠️ Depends on module          |
| **Interactive Privacy Mode Toggle** | ✅ Yes (Switch Allowed/Blocked anytime)       | ❌ No                                 | ❌ No                         |
| **Standalone (No Zygisk) Option**   | ✅ Yes                                        | ❌ No                                 | ❌ No                         |
| **Non-Root (LSPatch) Option**       | ✅ Yes (Patch any target APK)                 | ❌ No                                 | ❌ No                         |
| **Action Button Toggle & Logs**     | ✅ Yes                                        | ❌ No                                 | ❌ No                         |

> [!TIP]
> **Freedom of Choice:**
> Simple Flag Secure gives you complete freedom and flexibility! You aren't forced into any single framework or root method. Whether you prefer **Zygisk** (RAM-only), **Standalone** (framework overlay without Zygisk), or **LSPatch / LSPosed** (per-app without system modification or root), you can choose the exact variant tailored to your personal device setup and security preferences.

---

## 🚀 Choose Your Variant

Simple Flag Secure is available in three distinct variants:

| Variant               | ⚡ **Zygisk Edition**              | 🛡️ **Standalone Edition**                 | 📱 **LSPatch & LSPosed Edition**                                             |
| :-------------------- | :--------------------------------- | :---------------------------------------- | :--------------------------------------------------------------------------- |
| **Target User**       | Rooted users using Zygisk          | Rooted users wanting zero Zygisk overhead | **Non-root** users or LSPosed framework users                                |
| **Requirements**      | Any Zygisk implementation          | Magisk, KernelSU, or APatch               | [JingMatrix LSPatch](https://github.com/JingMatrix/LSPatch) or **LSPosed**    |
| **Filesystem Mounts** | **Zero mounts** (all hooks in RAM) | Clean on-device framework mount           | **None** (Embedded inside target APK or hooked via LSPosed)                 |
| **Size**              | **~19 KB** (Ultra-compact)         | **~172 KB** (Includes dex patcher)        | **~16.5 KB** (Compact helper APK)                                            |
| **Privacy Toggle**    | ✅ Action button / Volume key      | ✅ Action button / Volume key             | N/A (Always active in patched app / LSPosed scope)                           |

---

## 📱 Non-Root Users: LSPatch Setup Guide

If your device is not rooted (or you prefer not to touch root hooks), you can use the **LSPatch variant** (`Simple_Flag_Secure_LSPatch_v10.0.apk`) to patch any restricted app directly on your phone:

> [!NOTE]
> **Using LSPosed instead?**
> This exact same APK is a fully compliant standard Xposed module! If you have root with **LSPosed**, you can simply install `Simple_Flag_Secure_LSPatch_v10.0.apk`, enable it in the LSPosed Manager, check your target apps in its scope, and you are good to go!

### Recommended Tool

- **[JingMatrix LSPatch](https://github.com/JingMatrix/LSPatch)** (Recommended modern LSPatch fork for Android 10-15+)

### Step-by-Step Instructions:

1. **Download & Install**:
   - Install the latest **[JingMatrix LSPatch release](https://github.com/JingMatrix/LSPatch/releases)** APK on your device.
   - Download `Simple_Flag_Secure_LSPatch_v10.0.apk` from [Releases](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest).
2. **Open LSPatch**:
   - Open LSPatch and grant the requested storage permissions.
   - Go to the **Manage** tab → Tap the `+` button → Select **New Patch**.
3. **Select Target App**:
   - Choose the application where screenshots are blocked (either from installed apps or by picking an APK file directly).
4. **Embed Simple Flag Secure**:
   - Choose **Portable Mode** (embeds module directly so LSPatch app isn't needed later).
   - Under **Embed modules**, tap `+` and choose the downloaded `Simple_Flag_Secure_LSPatch_v10.0.apk`.
5. **Start Patching**:
   - Tap **Start Patching**. LSPatch will recompile and resign the target APK.
6. **Install the Patched App**:
   - Uninstall the original target app from your device (backup your data first!).
   - Install the patched APK produced by LSPatch.
7. **Done!** Screenshots and screen recordings are now permanently unlocked inside that app without requiring root access.

---

## ⚡ Rooted Users: Zygisk Edition Setup

### Recommended Zygisk Providers:

- **[Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext)** (Recommended for Magisk, KernelSU, and APatch)
- **[ReZygisk CLI (Pre-release)](https://github.com/PerformanC/ReZygisk)** (High performance alternative)
- Built-in Zygisk in Magisk

### Troubleshooting Zygisk Edition:

If the module reports `NOT WORKING` or screenshots are not unlocking on your setup:

1. **Use Zygisk Next or ReZygisk**: On **Zygisk Next** and **ReZygisk CI**, SFS works out of the box even with Umount / Exclude Modifications enabled on apps!
2. **Using Magisk Built-in Zygisk?**: Magisk's built-in Zygisk completely unloads modules for apps on the DenyList, which prevents screenshot detection hiding for those apps. If you use Magisk, simply install **[Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext)** or untick the app from DenyList.

---

## 🛡️ Rooted Users: Standalone Edition Setup

The **Standalone Edition** patches screenshot restrictions directly at boot without needing Zygisk, LSPosed, or any meta-modules (like NoMount or Hybrid Mount).

It operates completely standalone and hides itself well on most systems. However, on some stock ROMs with strict kernel protections (such as Samsung Knox / One UI), the kernel does not allow mounting from in-memory staging, forcing the module to fall back to legacy direct bind-mounting to ensure it still functions. On these devices, the fallback mount path may be detected unless:
- You have a kernel with **SusFS** support, or
- You use a meta-module like **NoMount** to hide the mount detection.

> [!TIP]
> If you are on Samsung Knox or a strict ROM and do not have SusFS or NoMount, simply use the **[⚡ Zygisk Edition](#-rooted-users-zygisk-edition-setup)** with the latest **Zygisk Next** or **ReZygisk**, which runs 100% in RAM with zero filesystem mounts.

---

## 🎛️ Privacy Mode (Instant Toggle)

Need to temporarily block screenshots and screen recordings for extra privacy? Simple Flag Secure includes a built-in **Privacy Mode** that lets you toggle states on the fly without rebooting your phone:

- **✅ ALLOWED**: Screenshots & recordings work everywhere.
- **❌ BLOCKED (Privacy Mode)**: Screenshots & recordings are blocked system-wide.

### How to use:

1. Tap the **Action** button in your root manager (Magisk, KernelSU, or APatch).
2. Press **Volume Up [Vol +]** within 30 seconds to instantly switch modes.
3. _(Bonus)_ Press **Volume Down [Vol -]** if you ever need to record a quick diagnostic log.

> [!TIP]
> You can also toggle it from a terminal (Termux) anytime:
>
> - Turn Privacy Mode ON (Blocked): `su -c "/data/adb/modules/simple_flag_secure*/action.sh block"`
> - Turn Privacy Mode OFF (Allowed): `su -c "/data/adb/modules/simple_flag_secure*/action.sh allow"`

---

## 📥 Installation Summary

1. **Download your preferred edition from [Releases](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest):**
   - ⚡ `Simple_Flag_Secure_Zygisk_v10.0.zip` (for Zygisk users)
   - 🛡️ `Simple_Flag_Secure_v10.1.zip` (for Standalone users)
   - 📱 `Simple_Flag_Secure_LSPatch_v10.0.apk` (for Non-Root LSPatch / LSPosed users)
2. **Installation by Variant:**
   - **For Zygisk & Standalone**: Flash the ZIP inside Magisk, KernelSU, or APatch manager → **Modules** → **Install from storage** → Reboot.
   - **For Non-Root (LSPatch) & LSPosed**: Follow the dedicated [📱 LSPatch & LSPosed Setup Guide](#-non-root-users-lspatch-setup-guide) above to patch your target apps with zero root, or install and enable it inside your LSPosed manager!
3. **Test:** Try taking a screenshot in an app that normally blocks it (e.g., Chrome Incognito).

---

## 📢 Important Note for Future Updates & Support

> [!IMPORTANT]
> **A message from the developer:**
> Due to current personal financial constraints, I cannot dedicate as much time to active daily maintenance or immediate personal support for this module.
> 
> **How you can help keep Simple Flag Secure alive:**
> 1. **Support via Donation**: If the module has helped you, even a small donation goes a long way toward keeping the project maintained.
> 2. **Self-Debug with AI & Community Contribution**:
>    - Simple Flag Secure has **built-in comprehensive diagnostic logging** (`[Vol -]` in the Action menu creates `sfs.log` + `sfs_report.tar.gz` in your Downloads folder).
>    - If you encounter an issue on your device, **feed your diagnostic logs directly into modern AI models** (like Gemini, Claude, or ChatGPT) to pinpoint why your ROM blocked screenshots or failed to mount!
>    - If you or an AI find a fix or optimization, **please open a Pull Request (PR)** so the entire community benefits!
> 3. **Telegram Discussion**: If you cannot resolve it yourself, report it with your `sfs.log` in our group: **[@BuildBytesDiscussion](https://telegram.me/BuildBytesDiscussion)**. Please understand that immediate individual support cannot be guaranteed.

---

## 🙏 Support & Donations

If you find Simple Flag Secure useful and would like to support its development:

- 💲 **Bhim (International UPI):** UPI ID - `shivamdhage@upi` | [Donate via QR](https://i.ibb.co/ZRm2xN2L/bhimupi.jpg)
- 💵 **GPay / UPI:** UPI ID - `shivamashokdhage6@oksbi` | [Donate via QR](https://i.ibb.co/5g4J2RXR/1f38d6d7-a8a2-4696-88e6-9cf503e0592c.png)
- 💰 **PayPal:** Username - `ShivamXD6` | [Donate via PayPal](https://www.paypal.com/paypalme/ShivamXD6)

---

## 🙌 Credits

- **[j-hc (ih8SecureLock)](https://github.com/j-hc/ih8SecureLock)** — For the in-app per-process `IPCThreadState` hook implementation concept.
- **[Varun Date (Disable-FLAG_SECURE)](https://github.com/VarunS2002/Xposed-Disable-FLAG_SECURE)** — For the original Xposed hook implementation concept used in the LSPatch / LSPosed edition.
- **[@dkvodao](https://telegram.me/dkvodao)** — Tested the Zygisk edition.
- **[@PParker110](https://telegram.me/PParker110)** — Tested the Standalone edition with fixes on OxygenOS / ColorOS 14 (OnePlus 9 Pro).
- **[@ShastikXD](https://telegram.me/ShastikXD)** (Dev) — Tested the Non-Root LSPatch edition.
- **[ShirigiriPatil](https://telegram.me/BosadBillaHun)** — Tested the module on KernelSU.
- **[LazyMeao](https://telegram.me/lazymeao)** & [@Black_luciferS](https://github.com/Blacklucifer82) — Tested on Realme UI 2.0 for compatibility and Toggle Action.
- **[ShishirThakur](https://telegram.me/Shishirsthakur)** — Tested screenshot detection functionality on Android 14+.
- **[Marmot](https://telegram.me/aptgo)** — Tested on MIUI Android 11 using SukiSU.
- **[@nyxnrv](https://github.com/777kzn)** — Tested on HyperOS Android 17 KernelSU.
- **[@Vikrant_R_Rajput](https://telegram.me/DeskAestheticx)** — Tested on Samsung OneUI Port Magisk.
- **[@idral](https://telegram.me/idral)** — Tested standalone mounting.
- **[@pocexa](https://telegram.me/pocexa)** — Tested on Poco X6 Pro for screenshot timeout issues.
