#!/system/bin/sh

ui_print "****************************************"
ui_print " ⚡ Simple Flag Secure (Zygisk Edition)"
ui_print "    Version: v8.0 (C++ Native Binder)"
ui_print "    Author:  @BuildBytes (@ShivamXD6)"
ui_print "****************************************"
ui_print ""

INSTALL_LOG="$MODPATH/sfs_install.log"
{
  echo "=== Simple Flag Secure (Zygisk) - Install Log ==="
  echo "Date: $(date)"
  echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
  echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
  echo "Architecture: $(getprop ro.product.cpu.abi)"
  echo "Root: $([ -n "$KSU" ] && echo "KernelSU" || { [ -n "$APATCH" ] && echo "APatch" || echo "Magisk"; })"
  echo "Zygisk Modules Detected:"
  ls -d /data/adb/modules/*zygisk* /data/adb/modules/*Zygisk* 2>/dev/null || echo "None found in /data/adb/modules"
  echo "Installed Libraries:"
  ls -la "$MODPATH/zygisk" 2>/dev/null
} > "$INSTALL_LOG" 2>&1
chmod 644 "$INSTALL_LOG" 2>/dev/null

if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
    ui_print "ℹ️ KernelSU / APatch detected:"
    ui_print "   Make sure a Zygisk provider (e.g. Zygisk Next / ReZygisk) is installed."
fi

ui_print ""
[ -f "$MODPATH/action.sh" ] && chmod 755 "$MODPATH/action.sh"

MARKER_FILE="/data/adb/.buildbytes"
if [ ! -f "$MARKER_FILE" ]; then
    touch "$MARKER_FILE" 2>/dev/null
    sleep 3
    am start -a android.intent.action.VIEW -d "tg://resolve?domain=BuildBytes" >/dev/null 2>&1 || \
    am start -a android.intent.action.VIEW -d "https://telegram.me/BuildBytes" >/dev/null 2>&1
fi

ui_print
ui_print "**************************************************"
ui_print " 🎛️ Allowed mode applied, Privacy mode is also available"
ui_print " 🔄 You can toggle modes anytime via Action button"
ui_print " ✨ All done! Please reboot your device now."
ui_print "**************************************************"
