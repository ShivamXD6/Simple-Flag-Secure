# Simple-Flag-Secure
>⚡Simple Flag Secure Magisk Module ⚡ to Disable Secure Flag and allow taking screenshots or screen recording in apps supports KSU/APatch inspired by Disable Flag Secure by MehediHJoy.

![Downloads](https://img.shields.io/github/downloads/ShivamXD6/Simple-Flag-Secure/total?color=green&style=for-the-badge)
![Release](https://img.shields.io/github/v/release/ShivamXD6/Simple-Flag-Secure?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Magisk](https://img.shields.io/badge/Magisk-8A2BE2?style=for-the-badge&logo=magisk&logoColor=white)
![Root](https://img.shields.io/badge/Root-ff0000?style=for-the-badge&logo=superuser&logoColor=white)

## ❔ Why this module? When there's already Disable Flag Secure by MehediHJoy.

- 💾 **Lightweight**: No bloated binaries or extras — faster and minimal than MehediHJoy's version.
- ⭐ **Root Managers Support**: Fully compatible with Magisk, KernelSU, APatch and their forks, unlike the outdated original.
- 🖥️ **Dex-Only Patch**: Only modifies required DEX files, avoiding issues like broken power button on Android 14.
- 💬 **Readable Code**: Clean, commented code with fewer lines (300 vs 2000), easy to understand.
- 🔄 **Fast Restore**: Creates backup of services.jar for quicker reflash after removal.
- ⚙️ **Optimized Module Structure**: Reduced redundancy and cleaned up code for better maintainability.
- 🚫 **Screenshot Detection Blocked**: Prevents apps from detecting when a screenshot is taken.
- 🔗 **Improved Support & Compatibility**: Better handling on newer Android versions and different environments.
- ⚡ **Boosted I/O Performance**: Uses fstrim and similar commands to improve performance during installation.
- 📱 **OEM Compatibility**: May work on popular OEM skins like Realme UI, ColorOS, HyperOS, and One UI.

> [!NOTE]
> You can remove the backup if you want by deleting this directory /data/#SFS

## 📥 Installation Guide

🚫📸 Removing screenshot restrictions is simple. Just follow these steps:

1️⃣ **Install Module**: Open Magisk/KSU/APatch Manager → Modules → Tap '+' → Select Simple Flag Secure zip.

💾 **(Optional)**: Save logs via top-right disk icon — helpful if module doesn't work.

🔁 **Reboot Device**: Restart your device to apply changes.

✅ **Test It**: Try taking screenshots (e.g. WhatsApp profile pic) to confirm it's working.


## 🧰 Troubleshooting

🔄 **If bootloop or system doesn't boot**:

1️⃣ Reboot into Recovery (TWRP or other).  
2️⃣ Go to: `/data/adb/modules/SimpleFlagSecure`  
3️⃣ Delete the `SimpleFlagSecure` folder.  
4️⃣ Reboot system and report on **[Telegram](https://telegram.me/ShastikXD)**.


🚫 **If the module doesn’t work**:

1️⃣ Copy `services.jar` from `/system/framework/` to internal storage (use root file manager).  
2️⃣ Send the `services.jar` to **[Telegram](https://telegram.me/ShastikXD)**.  
3️⃣ Delete `/data/#SFS` from root directory.  
4️⃣ Reflash the module and **save logs** during install.  
5️⃣ Send logs from `sdcard/Download/Magisk|KSU|APatch_install_logs` to **[Telegram](https://telegram.me/ShastikXD)**.

📬 **Need help?** Message me anytime on **[Telegram](https://telegram.me/ShastikXD)**.

## 🙏 Support & Donations

If you find Simple Flag Secure helpful and want to support development, you can donate here:

💰 **PayPal:** [Donate via PayPal](https://paypal.me/ShivamXD6)

📲 **SuperMoney:** UPI ID - **shivam.dhage@superyes**

🔗 **GPay UPI QR Code:** [Donate via UPI QR](https://i.ibb.co/5g4J2RXR/1f38d6d7-a8a2-4696-88e6-9cf503e0592c.png)

Every contribution helps keep the project alive and improved! Thank you! 😊

## 🙌 Credits

💡 **[MehediHJoy](https://xdaforums.com/t/module-disable-flag-secure-v9-0-by-mehedi-h-joy.4490475/)**  
Idea originator and source reference for this module.

🧪 **[ShirigiriPatil](https://telegram.me/BosadBillaHun)**  
Tested the module on KernelSU (KSU).

📱 **[LazyMeao](https://telegram.me/lazymeao)**  
Tested on Realme UI 2.0 for compatibility.

🕵️ **[ShishirThakur](https://telegram.me/Shishirsthakur)**  
Helped test screenshot detection functionality.

