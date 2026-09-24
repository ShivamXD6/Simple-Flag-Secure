# Simple Flag Secure v7 Changelog

- **Action Button Mode Toggle**: Switch dynamically between **ALLOWED** (screenshots unblocked) and **BLOCKED** (privacy mode) directly from Magisk, KernelSU, or APatch Manager — no reboot required.

- **Fixed OnePlus Power Button Issue**: Fixed broken power button and hardware key combinations on OnePlus (OxygenOS/ColorOS) devices by patching `verify`.

- **Zero Dependencies**: Full standalone mounting for KernelSU and APatch without requiring Meta-Module, while remaining fully compatible with it.

- **Smart SystemUI Reload**: Automatically reloads SystemUI after toggling with a 3-second delay and safety notification, applying changes system-wide without killing background apps.

- **Action Button Guard**: Prevents invalid toggles and SystemUI restarts when `services.jar` isn't mounted, while alerting the user and logging the failure.

- **Live Mount Status**: Displays real-time mount health (`[Mount: OK]` / `[Mount: FAIL]`) directly in the module manager.

- **Boot Integrity & Health Check**: Performs fast binary mount checks on boot with automatic status notifications.

- **Built-in Auto Diagnostics**: Added `action.sh debug` to generate targeted logs for mount health, window focus, secure flags, and OEM policies such as OnePlus `StrategyBlackscreenshot`.

- **Rich Shell Notifications**: Added notifications for mode changes, boot mount status, and installation completion.

- **Direct Manager Updates**: Added one-click update checking and downloading through Magisk, KernelSU, and APatch.

- **Auto-Cleanup**: Diagnostic logs and temporary files are automatically removed when the module is uninstalled.
