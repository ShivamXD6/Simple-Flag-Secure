#!/system/bin/sh

MODPATH="${0%/*}"
BIN="$MODPATH/system/bin"
STOCK="/system/framework"
MOD="$MODPATH/system/framework"
ARCH=$(getprop ro.product.cpu.abi)

mkdir -p "$MOD" "$BIN"

LAST_MSG=""
notify() {
    local TITLE="$1"
    local MSG="$2"
    local ICON="${3:-@android:drawable/stat_sys_download_done}"
    if [ "$MSG" != "$LAST_MSG" ]; then
        local SAFE_MSG=$(printf '%b' "$MSG" | sed "s/'/'\\\\''/g")
        su -lp 2000 -c "cmd notification post -i '$ICON' -S bigtext -t '$TITLE' 'SFS_INSTALL' '$SAFE_MSG'" >/dev/null 2>&1
        LAST_MSG="$MSG"
    fi
}

padh() {
  grep -m 1 "^$1=" "$2" 2>/dev/null | sed 's/^.*=//'
}

ADBDIR="/data/adb"
if [ -d "$ADBDIR/magisk" ] && magisk -V >/dev/null 2>&1; then
  ROOT="Magisk"
elif [ -d "$ADBDIR/ksu" ] && ksud -V >/dev/null 2>&1; then
  ROOT="KernelSU"
elif [ -d "$ADBDIR/ap" ] && apd -V >/dev/null 2>&1; then
  ROOT="APatch"
else
  ROOT="Unknown"
fi

if [ "$ROOT" != "Magisk" ] && [ -d "$ADBDIR/metamodule" ]; then
  MOUNT_MODE="Meta-Module"
else
  MOUNT_MODE="Standalone"
fi

echo "###################################"
echo " 👀 $(padh "name" "$MODPATH/module.prop")"
echo " 🌟 Made By $(padh "author" "$MODPATH/module.prop")"
echo " ⚡ Version - $(padh "version" "$MODPATH/module.prop")"
echo " 💻 Architecture - $ARCH"
echo " 📂 Mounted: $MOUNT_MODE"
if [ "$MOUNT_MODE" = "Standalone" ]; then
  echo " ℹ️ Notice: Standalone mode (No Meta-Module required, but compatible)"
fi
echo "###################################"
echo

jar_path="$STOCK/services.jar"
jar_name="services.jar"

if [ ! -f "$jar_path" ]; then
  echo "❌ $jar_path not found!"
  exit 1
fi

if ! unzip -l "$jar_path" | grep -q classes.dex; then
  echo "❌ You need a deodexed $jar_name"
  exit 1
fi

echo "=================================================="
echo " ⚡ Patching $jar_name (parallel dexlib2)..."
echo "=================================================="

setprop persist.sys.sfs.screenshot true

dalvikvm -Xmx512m -Djava.io.tmpdir="$MOD" -cp "$BIN/sfs.jar" build.bytes.sfs.SfsPatcher "$jar_path" "$MOD/$jar_name" || {
  echo "💥 Dalvik patcher failed for $jar_name"
  exit 1
}

[ -f "$MODPATH/action.sh" ] && chmod 755 "$MODPATH/action.sh"
[ -f "$MODPATH/service.sh" ] && chmod 755 "$MODPATH/service.sh"
[ -f "$MODPATH/post-fs-data.sh" ] && chmod 755 "$MODPATH/post-fs-data.sh"

rm -f "$MODPATH/disable.sh"
rm -rf "$BIN"

rm -rf /data/dalvik-cache/* 2>/dev/null

echo
echo "**************************************************"
echo " 🎛️ Action Button: Enabled in Magisk/KSU/APatch"
echo " 🔄 You can toggle mode anytime via Action button"
echo " 📝 Install Log: Auto-saved to /sdcard/Download"
echo " ✨ All done! Please reboot your device now."
echo "**************************************************"

notify "✨ INSTALLED • Simple Flag Secure" "Install done! Please reboot now. Join @BuildBytes for future projects that save your time & headache!"
sleep 3
am start -a android.intent.action.VIEW -d "tg://resolve?domain=BuildBytes" >/dev/null 2>&1 || \
am start -a android.intent.action.VIEW -d https://telegram.me/BuildBytes >/dev/null 2>&1