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

BASE_DESC="Bypasses screenshot restrictions & hides screenshot detection (A14+). Supports Magisk, KernelSU & APatch, no Zygisk, LSPosed or Meta Module required."

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Wait for unlock
count=0
while [ ! -d "/storage/emulated/0" ] && [ "$count" -lt 30 ]; do
    sleep 2
    count=$((count + 1))
done

# Stabilize delay
sleep 3

# Root & mount mode detection
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

MOD_JAR="$MODDIR/system/framework/services.jar"
SYS_JAR="/system/framework/services.jar"

# Fast binary mount check
if [ -f "$MOD_JAR" ] && cmp -s "$MOD_JAR" "$SYS_JAR" 2>/dev/null; then
    CURRENT=$(getprop persist.sys.sfs.screenshot)

    if [ "$CURRENT" = "false" ]; then
        STATUS="BLOCKED"
        ICON="🔒"
    else
        STATUS="ALLOWED"
        ICON="🔓"
    fi

    sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null

    # Boot mount notification
    if [ "$MOUNT_MODE" = "Standalone" ]; then
        notify "Simple Flag Secure" "Mounted (Standalone). No Meta-Module needed, but compatible with it! Screenshots unblocked."
    else
        notify "Simple Flag Secure" "Mounted (Meta-Module). Screenshots unblocked everywhere!"
    fi
else
    # Mount failed - trigger debug dump and alert user
    [ -f "$MODDIR/action.sh" ] && sh "$MODDIR/action.sh" debug

    # Fallback log write if action.sh didn't generate log
    if [ ! -f "$LOG_FILE" ]; then
        {
            echo "=================================================="
            echo "       Simple Flag Secure - Diagnostic Log"
            echo "=================================================="
            echo "Time: $(date)"
            echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model)"
            echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
            echo "Root Manager: $ROOT"
            echo "Mount Mode: $MOUNT_MODE"
            echo
            echo "--- [Mount Check: FAILED] ---"
            echo "Stock JAR:   $SYS_JAR"
            echo "Module JAR:  $MOD_JAR"
            echo "services.jar does not match module patched file!"
            echo "KernelSU/APatch standalone mount or overlayfs failed to mount."
            echo
            echo "--- [Active Mounts] ---"
            grep 'services.jar' /proc/mounts 2>/dev/null || echo "No bind mounts for services.jar found."
            echo
            echo "=================================================="
            echo "Send this log to @BuildBytes on Telegram:"
            echo "🔗 https://telegram.me/BuildBytes"
            echo "=================================================="
        } > "$LOG_FILE" 2>&1
        chmod 644 "$LOG_FILE" 2>/dev/null
    fi

    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    notify "Simple Flag Secure" "⚠️ Module isn't working: services.jar not mounted! Check sfs_debug.log in module folder."
fi
