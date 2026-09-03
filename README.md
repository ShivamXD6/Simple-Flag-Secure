# Simple Flag Secure

> 👀 A lightweight root module that disables Android's `FLAG_SECURE`, allowing screenshots and screen recording in apps that normally block them. It also prevents apps from detecting screenshots on Android 14+. Supports Magisk, KernelSU, APatch, and their forks.

[![Downloads](https://img.shields.io/github/downloads/ShivamXD6/Simple-Flag-Secure/total?color=green\&style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Release](https://img.shields.io/github/v/release/ShivamXD6/Simple-Flag-Secure?style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Join Build Bytes](https://img.shields.io/badge/Join-Build%20Bytes-2CA5E0?style=for-the-badge\&logo=telegram)](https://telegram.me/BuildBytes)
[![Join Chat](https://img.shields.io/badge/Join%20Chat-Build%20Bytes%20Discussion-2CA5E0?style=for-the-badge\&logo=telegram)](https://telegram.me/BuildBytesDiscussion)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge\&logo=android\&logoColor=white)
![Root](https://img.shields.io/badge/Root-ff0000?style=for-the-badge\&logo=superuser\&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge\&logo=magisk\&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-000000?style=for-the-badge\&logo=linux\&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-FF6B00?style=for-the-badge\&logo=android\&logoColor=white)

## ❔ Why Simple Flag Secure?

You may be wondering: **Why use this when [Disable Flag Secure by MehediHJoy](https://xdaforums.com/t/module-disable-flag-secure-v9-0-by-mehedi-h-joy/) already exists?**

Simple Flag Secure focuses on being lightweight, maintainable, and compatible with newer Android versions and root solutions.

* 🚫 **Screenshot Detection Blocking** — Prevents apps from detecting when a screenshot is taken.
* ⭐ **Modern Root Manager Support** — Supports Magisk, KernelSU, APatch, and their forks.
* 💾 **Lightweight** — No unnecessary binaries or additional components. Designed to be minimal and fast.
* 🖥️ **DEX-Only Patching** — Modifies only the required DEX files, helping avoid side effects such as the broken power button issue reported on Android 14.
* 💬 **Clean & Readable Code** — Small, commented codebase with fewer than 300 lines compared to the original's 2,000+ lines.
* 🔄 **Fast Restore** — Automatically backs up `services.jar`, making restoration and reflashing faster after removal.
* ⚙️ **Optimized Structure** — Reduced redundancy and simplified the module structure for easier maintenance.
* 🔗 **Improved Compatibility** — Better handling of newer Android versions and different system environments.
* 📱 **OEM Compatibility** — May work on OEM skins such as Realme UI, ColorOS, HyperOS, and One UI.

> [!NOTE]
> The `services.jar` backup is stored in `/data/#SFS`.
>
> You can remove the backup manually by deleting `/data/#SFS`, or select **Clean Flash** while installing/reflashing the module.

## 📥 Installation

> [!IMPORTANT]
> On **latest KernelSU or APatch kernels**, make sure **[Mountify](https://github.com/backslashxx/mountify)** is installed and configured correctly before installing this module if not install that first.

Removing screenshot restrictions is straightforward:

1. **Install the Module**
   Open your Magisk, KernelSU, or APatch manager → **Modules** → **Install from storage** → Select the **Simple Flag Secure** ZIP.

2. **Save Installation Logs (Optional)**
   Use the **disk icon in the top-right corner** to save installation logs. These logs are useful for troubleshooting if the module doesn't work.

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
4. Reboot into Android.
5. Report the issue in the **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)** group.

### 🚫 Module Doesn't Work

If the module installs successfully but doesn't work:

1. Copy `services.jar` from:
   `/system/framework/services.jar`
2. Send the file to the **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)** group.
3. Delete:
   `/data/#SFS`
4. Reflash the module.
5. **Save the installation logs** using the disk icon in the installer.
6. Send the logs from:
   `sdcard/Download/Magisk|KSU|APatch_install_logs`
   to the **[Build Bytes Discussion](https://telegram.me/BuildBytesDiscussion)** group.

## 🙏 Support & Donations

If you find Simple Flag Secure useful and would like to support its development:

* 💰 **PayPal:** [Donate via PayPal](https://paypal.me/ShivamXD6)
* 📲 **SuperMoney:** UPI ID — **shivam.dhage@superyes**
* 🔗 **GPay / UPI:** [Donate via UPI QR](https://i.ibb.co/5g4J2RXR/1f38d6d7-a8a2-4696-88e6-9cf503e0592c.png)

Your support helps keep the project maintained and improve compatibility with newer Android versions.

## 🙌 Credits

* **[MehediHJoy](https://xdaforums.com/t/module-disable-flag-secure-v9-0-by-mehedi-h-joy/)**
  Original idea and source reference for this module.

* **[ShirigiriPatil](https://telegram.me/BosadBillaHun)**
  Tested the module on KernelSU.

* **[LazyMeao](https://telegram.me/lazymeao)** & **[ASIF](https://telegram.me/asif_adi)**
  Tested the module on Realme UI 2.0 for compatibility.

* **[ShishirThakur](https://telegram.me/Shishirsthakur)**
  Helped test screenshot detection functionality.

* **[Marmot](https://telegram.me/aptgo)**
  Tested the module on MIUI Android 11 using SukiSU, a KernelSU fork, helping verify compatibility and stability.
