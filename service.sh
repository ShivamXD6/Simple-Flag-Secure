#!/system/bin/sh
MODDIR="${0%/*}"
[ "$MODDIR" = "$0" ] && MODDIR="."
[ -d "$MODDIR" ] || MODDIR="/data/adb/modules/simple_flag_secure"
LOG_FILE="$MODDIR/sfs_debug.log"

notify() {
    local TITLE="$1"
    local MSG="$2"
    local ICON="${3:-@android:drawable/ic_dialog_info}"
    local TAG="${4:-SFS_BOOT}"
    local SAFE_MSG=$(printf '%b' "$MSG" | sed "s/'/'\\\\''/g")
    su 2000 -c "cmd notification post -i '$ICON' -t '$TITLE' -S bigtext '$TAG' '$SAFE_MSG'" >/dev/null 2>&1 || \
    cmd notification post -i "$ICON" -t "$TITLE" -S bigtext "$TAG" "$SAFE_MSG" >/dev/null 2>&1
}

BASE_DESC="Bypasses screenshot restrictions and hides screenshot detection."

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

count=0
while [ ! -d "/storage/emulated/0" ] && [ "$count" -lt 30 ]; do
    sleep 2
    count=$((count + 1))
done

sleep 3

MOD_JAR="$MODDIR/services.jar"
SYS_JAR="/system/framework/services.jar"

if [ -f "$MOD_JAR" ] && cmp -s "$MOD_JAR" "$SYS_JAR" 2>/dev/null; then
    CURRENT=$(getprop persist.sys.sfs.screenshot)

    if [ "$CURRENT" = "false" ]; then
        STATUS="BLOCKED"
        ICON="❌"
        NOTIF_ICON="@android:drawable/ic_menu_close_clear_cancel"
    else
        STATUS="ALLOWED"
        ICON="✅"
        NOTIF_ICON="@android:drawable/ic_menu_view"
    fi

    sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null

    if [ "$CURRENT" = "false" ]; then
        NOTIF_BODY="Mounted (Standalone). Privacy Mode active: screenshots blocked everywhere."
    else
        NOTIF_BODY="Mounted (Standalone). Screenshots and recordings allowed everywhere!"
    fi
    notify "$ICON $STATUS • Simple Flag Secure" "$NOTIF_BODY" "$NOTIF_ICON" "SFS_BOOT"
else
    [ -f "$MODDIR/action.sh" ] && sh "$MODDIR/action.sh" debug >/dev/null 2>&1 &

    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    notify "Simple Flag Secure" "⚠️ Module isn't working: services.jar not mounted! Use Action button to export sfs.log." "@android:drawable/stat_sys_warning"
fi
