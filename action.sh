#!/system/bin/sh
MODDIR="${0%/*}"
[ "$MODDIR" = "$0" ] && MODDIR="."
[ -d "$MODDIR" ] || MODDIR="/data/adb/modules/simple_flag_secure"
LOG_FILE="$MODDIR/sfs_debug.log"

LAST_MSG=""
notify() {
    local TITLE="$1"
    local MSG="$2"
    if [ "$MSG" != "$LAST_MSG" ]; then
        local SAFE_MSG=$(printf '%b' "$MSG" | sed "s/'/'\\\\''/g")
        su -lp 2000 -c "cmd notification post -S bigtext -t '$TITLE' 'Status' '$SAFE_MSG'" >/dev/null 2>&1
        LAST_MSG="$MSG"
    fi
}

BASE_DESC="Bypasses screenshot restrictions and hides screenshot detection (A14+). Supports Magisk, KernelSU and APatch, no Zygisk, LSPosed or Meta Module required."

# Root detection
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

# Mount check
MOD_JAR="$MODDIR/system/framework/services.jar"
SYS_JAR="/system/framework/services.jar"

if [ -f "$MOD_JAR" ] && cmp -s "$MOD_JAR" "$SYS_JAR" 2>/dev/null; then
    MOUNT_OK=true
    MOUNT_LABEL="OK"
else
    MOUNT_OK=false
    MOUNT_LABEL="FAIL"
fi

dump_debug() {
    local DUMP_WIN=$(dumpsys window 2>/dev/null)
    {
        echo "=================================================="
        echo "       Simple Flag Secure - Diagnostic Log"
        echo "=================================================="
        echo "Time: $(date)"
        echo "Module Version: $(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "ROM Build: $(getprop ro.build.display.id)"
        echo "SELinux: $(getenforce 2>/dev/null)"
        echo "Root Manager: $ROOT"
        echo
        echo "--- [services.jar Mount Check] ---"
        echo "Stock JAR:   $SYS_JAR"
        echo "Module JAR:  $MOD_JAR"
        if [ "$MOUNT_OK" = "true" ]; then
            echo "Mount Status: [OK] Patched services.jar is mounted!"
        else
            echo "Mount Status: [FAIL] services.jar is NOT mounted or differs from module!"
        fi
        echo
        echo "--- [Active Mounts] ---"
        grep 'services.jar' /proc/mounts 2>/dev/null || echo "No direct bind mounts found for services.jar"
        echo
        echo "--- [SFS Properties] ---"
        echo "persist.sys.sfs.screenshot: $(getprop persist.sys.sfs.screenshot)"
        echo
        echo "--- [Window Focus & Secure State] ---"
        echo "$DUMP_WIN" | grep -E 'mCurrentFocus|mFocusedApp' | head -n 5
        echo "$DUMP_WIN" | grep -iE 'mHasSecure|isSecure|FLAG_SECURE|canBeScreenshotTarget|notAllowCaptureDisplay|hasSecure' | head -n 25
        echo
        echo "--- [Window Policy & Screenshot Strategies] ---"
        dumpsys window policy 2>/dev/null | grep -iE 'screenshot|secure|Strategy|KeyCombination|mSafeMode|mSystemReady' | head -n 25
        echo
        echo "--- [Recent Relevant Logs / Denials] ---"
        logcat -d -t 500 2>/dev/null | grep -iE 'sfs|screenshot|flag_secure|services|avc.*denied|SurfaceFlinger|PhoneWindowManager|ScreenshotController|StrategyBlackscreenshot' | tail -n 35
        echo
        echo "=================================================="
        echo "Send this log to @BuildBytes on Telegram:"
        echo "🔗 https://telegram.me/BuildBytes"
        echo "=================================================="
    } > "$LOG_FILE" 2>&1
    chmod 644 "$LOG_FILE" 2>/dev/null
}

# If debug requested, dump log and exit
if [ "$1" = "debug" ]; then
    dump_debug
    [ -t 1 ] && cat "$LOG_FILE" 2>/dev/null
    exit 0
fi

# If mount failed, abort toggle completely
if [ "$MOUNT_OK" != "true" ]; then
    dump_debug
    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    echo "=================================================="
    echo "        Simple Flag Secure - Action Toggle"
    echo "=================================================="
    echo "  ❌ Mount Error: services.jar is NOT mounted!"
    echo "  Cannot toggle modes while module is inactive."
    echo "  Debug log: $LOG_FILE"
    echo "  Help:      https://telegram.me/BuildBytes"
    echo "=================================================="
    notify "Simple Flag Secure" "❌ Cannot toggle: services.jar is not mounted! Check sfs_debug.log in module folder."
    exit 1
fi

# Read current setting (default true)
CURRENT=$(getprop persist.sys.sfs.screenshot)

# Handle CLI arguments
TARGET=""
case "$1" in
  allow|ALLOW|true|1) TARGET="true" ;;
  block|BLOCK|false|0) TARGET="false" ;;
  toggle|TOGGLE|"")
    [ "$CURRENT" = "false" ] && TARGET="true" || TARGET="false"
    ;;
  status|STATUS)
    echo "Status: ${CURRENT:-true}"
    echo "Mount:  $MOUNT_LABEL"
    exit 0
    ;;
esac

if [ "$TARGET" = "true" ]; then
  STATUS="ALLOWED"
  ICON="🔓"
  DESC="Screenshots and recordings allowed everywhere"
else
  STATUS="BLOCKED"
  ICON="🔒"
  DESC="Screenshots and recordings blocked everywhere (Privacy Mode)"
fi

setprop persist.sys.sfs.screenshot "$TARGET"

# Generate diagnostic log
dump_debug

# Update module description
sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null

echo "=================================================="
echo "        Simple Flag Secure - Action Toggle"
echo "=================================================="
echo "  Status: $ICON $STATUS"
echo "  Mount:  ✅ OK"
echo "  Prop:   persist.sys.sfs.screenshot = $TARGET"
echo "  Debug:  $LOG_FILE"
echo "  Help:   https://telegram.me/BuildBytes"
echo "--------------------------------------------------"
echo "  ⏳ Restarting SystemUI in 3 seconds to apply..."
echo "  (Screen will reload briefly, don't panic! 😊)"
echo "=================================================="

# Post notification
notify "Simple Flag Secure" "Switched to $STATUS: $DESC. Restarting SystemUI in 3s..."

# Wait and restart SystemUI
sleep 3
killall com.android.systemui 2>/dev/null || pkill -f com.android.systemui 2>/dev/null || kill -9 $(pidof com.android.systemui) 2>/dev/null
