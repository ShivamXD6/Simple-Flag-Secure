#!/system/bin/sh

MODPATH="${0%/*}"
BIN="$MODPATH/system/bin"
STOCK="/system/framework"
MOD="$MODPATH/system/framework"
ARCH=$(getprop ro.product.cpu.abi)

mkdir -p "$MOD" "$BIN"

# Normalize backslash path if extracted by Windows zip tools
if [ -f "$MODPATH/system\\bin\\patcher.jar" ]; then
  mv -f "$MODPATH/system\\bin\\patcher.jar" "$BIN/patcher.jar"
fi

# Read properties
padh() {
  grep -m 1 "^$1=" "$2" 2>/dev/null | sed 's/^.*=//'
}

# UI Banner
echo "###################################"
echo " 👀 $(padh "name" "$MODPATH/module.prop")"
echo " 🌟 Made By $(padh "author" "$MODPATH/module.prop")"
echo " ⚡ Version - $(padh "version" "$MODPATH/module.prop")"
echo " 💻 Architecture - $ARCH"
echo "###################################"
echo

# KernelSU / APatch Metamodule Notice
if [ "$KSU" = "true" ] || [ -d "/data/adb/ksu" ] || [ "$APATCH" = "true" ] || [ -d "/data/adb/ap" ]; then
  echo "📢 [KernelSU / APatch Detected]"
  echo "   ⚠️ Notice: Make sure a metamodule (e.g. Mountify"
  echo "   or Magic Mount) is enabled if overlayfs is inactive."
  echo
fi

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

dalvikvm -Xmx512m -Djava.io.tmpdir="$MOD" -cp "$BIN/patcher.jar" build.bytes.sfs.SfsPatcher "$jar_path" "$MOD/$jar_name" || {
  echo "💥 Dalvik patcher failed for $jar_name"
  exit 1
}

# Cleanup installer binaries from installed module to save space
rm -f "$MODPATH/disable.sh"
rm -rf "$BIN"

echo
echo "**************************************************"
echo " 🔗 Channel: @BuildBytes"
echo " ✨ All done! Please reboot your device now."
echo "**************************************************"