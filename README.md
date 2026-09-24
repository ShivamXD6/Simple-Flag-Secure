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

- 🛠️ **No Zygisk or LSPosed Required** - No need to installa anything extra like Zygisk, LSPosed or any Meta-Module, it works without them.
- 🚫 **Screenshot Detection Blocking** — Prevents apps from detecting when a screenshot is taken like in Snapchat or WhatsApp (only on Android 14+).
- 🎛️ **Action Button Mode Toggle** — Switch between ALLOWED and BLOCKED (Privacy Mode) directly from your manager without rebooting.
- 🩺 **Built-in Auto Diagnostics** — Easily generate targeted diagnostic logs (`sfs_debug.log`) via Action button or `action.sh debug`.
- ⭐ **Modern Root Manager Support** — Supports Magisk, KernelSU, APatch, and their forks.
- 🔄 **In-App Manager Updates** — Native support for one-click updates inside root managers via `updateJson`.
- 💾 **Lightweight & Standalone** — Zero dependencies. Mounts standalone or with MetaModule.
- ⚡ **Much Faster** — Uses dexlib2 patcher with parallel processing for faster patching of flags.
- 🖥️ **DEX-Only Patching** — Modifies only the required DEX files, helping avoid side effects such as the broken power button issue reported on Android 14+.
- 📱 **OEM Compatibility** — Supports OEM skins such as Realme UI, ColorOS, OxygenOS, HyperOS, and One UI.

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

### 🚫 Module Doesn't Work

If the module installs successfully but doesn't work:

1. Open the app where screenshots are failing and try taking a screenshot once.
2. Run this command in Termux:
   ```sh
   su -c "sh /data/adb/modules/simple_flag_secure/action.sh debug"
   ```
3. Grab the generated log from `/data/adb/modules/simple_flag_secure/sfs_debug.log`.
4. Send the log file to the **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)** group for instant support!

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
