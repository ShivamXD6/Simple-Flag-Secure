# Simple-Flag-Secure
>👀 Simple Flag Secure Magisk Module to Disable Secure Flag and allow taking screenshots or screen recording in apps that won't allow also hide screenshot detection on A14+, supports KSU/APatch inspired by Disable Flag Secure by MehediHJoy.

[![Downloads](https://img.shields.io/github/downloads/ShivamXD6/Simple-Flag-Secure/total?color=green&style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Release](https://img.shields.io/github/v/release/ShivamXD6/Simple-Flag-Secure?style=for-the-badge)](https://github.com/ShivamXD6/Simple-Flag-Secure/releases/latest)
[![Join Build Bytes](https://img.shields.io/badge/Join-Build%20Bytes-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytes)
[![Join Chat](https://img.shields.io/badge/Join%20Chat-Build%20Bytes%20Discussion-2CA5E0?style=for-the-badge&logo=telegram)](https://telegram.me/BuildBytesDiscussion)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Root](https://img.shields.io/badge/Root-ff0000?style=for-the-badge&logo=superuser&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![KernelSU](https://img.shields.io/badge/KernelSU-000000?style=for-the-badge&logo=linux&logoColor=white)
![APatch](https://img.shields.io/badge/APatch-FF6B00?style=for-the-badge&logo=android&logoColor=white)

## ❔ Why this module? When there's already Disable Flag Secure by MehediHJoy.

- 🚫 **Screenshot Detection Blocked**: Prevents apps from detecting when a screenshot is taken.
- ⭐ **Root Managers Support**: Fully compatible with Magisk, KernelSU, APatch and their forks, unlike the outdated original.
- 💾 **Lightweight**: No bloated binaries or extras, faster and minimal than MehediHJoy's version.
- 🖥️ **Dex-Only Patch**: Only modifies required DEX files, avoiding issues like broken power button on Android 14.
- 💬 **Readable Code**: Clean, commented code with fewer lines (<300 vs 2000>), easy to understand.
- 🔄 **Fast Restore**: Creates backup of services.jar for quicker reflash after removal.
- ⚙️ **Optimized Module Structure**: Reduced redundancy and cleaned up code for better maintainability.
- 🔗 **Improved Support & Compatibility**: Better handling on newer Android versions and different environments.
- 📱 **OEM Compatibility**: May work on popular OEM skins like Realme UI, ColorOS, HyperOS, and One UI.

> [!NOTE]
> You can remove the backup if you want by either deleting this directory `/data/#SFS` manually, or select clean flash while flashing.

## 📥 Installation Guide

📸 Removing screenshot restriction is simple. Just follow these steps:

1️⃣ **Install Module**: Open Magisk/KSU/APatch Manager → Modules → Tap '+' → Select Simple Flag Secure zip.

💾 **(Optional)**: Save logs via top-right disk icon, helpful if the module doesn't work.

🔁 **Reboot Device**: Restart your device to apply changes.

✅ **Test It**: Try taking screenshots (e.g. WhatsApp profile pic or chrome incognito) to confirm it's working.


## 🧰 Troubleshooting

🔄 **If bootloop or system doesn't boot**:

1️. Reboot into Recovery (TWRP or other).  
2️. Go to: `/data/adb/modules/simple_flag_secure`  
3️. Delete the `simple_flag_secure` folder.  
4️. Reboot system and report on **[Telegram](https://telegram.me/BuildBytesDiscussion)**.


🚫 **If the module doesn’t work**:

1️. Copy `services.jar` from `/system/framework/` to internal storage (use root file manager).  
2️. Send the `services.jar` to **[Telegram](https://telegram.me/BuildBytesDiscussion)**.  
3️. Delete `/data/#SFS` from root directory.  
4️. Reflash the module and **save logs** during install.  
5️. Send logs from `sdcard/Download/Magisk|KSU|APatch_install_logs` to **[Telegram](https://telegram.me/BuildBytesDiscussion)**.

## 🙏 Support & Donations

If you find Simple Flag Secure helpful and want to support development, you can donate here:

💰 **PayPal:** [Donate via PayPal](https://paypal.me/ShivamXD6)

📲 **SuperMoney:** UPI ID - **shivam.dhage@superyes**

🔗 **GPay UPI QR Code:** [Donate via UPI QR](https://i.ibb.co/5g4J2RXR/1f38d6d7-a8a2-4696-88e6-9cf503e0592c.png)

Every contribution helps keep the project alive and improved! Thank you! 😊

## 🙌 Credits

- **[MehediHJoy](https://xdaforums.com/t/module-disable-flag-secure-v9-0-by-mehedi-h-joy/)**  
  Idea originator and source reference for this module.

- **[ShirigiriPatil](https://telegram.me/BosadBillaHun)**  
  Tested the module on KernelSU (KSU).

- **[LazyMeao](https://telegram.me/lazymeao)** & **[ASIF](https://telegram.me/asif_adi)**  
  Tested on Realme UI 2.0 for compatibility.

- **[ShishirThakur](https://telegram.me/Shishirsthakur)**  
  Helped test screenshot detection functionality.

- **[Marmot](https://telegram.me/aptgo)**  
  Tested the module on MIUI Android 11 using SukiSU (a KernelSU fork), helping verify compatibility and stability.
