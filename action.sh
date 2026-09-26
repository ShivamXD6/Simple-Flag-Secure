#!/system/bin/sh
MODDIR="${0%/*}"
[ "$MODDIR" = "$0" ] && MODDIR="."
[ -d "$MODDIR" ] || MODDIR="/data/adb/modules/simple_flag_secure"
LOG_FILE="$MODDIR/sfs_debug.log"
LOGCAT_PID_FILE="$MODDIR/.logcat.pid"
LOGCAT_TMP="$MODDIR/.logcat_recording.tmp"

BASE_DESC="Bypasses screenshot restrictions and hides screenshot detection (A14+). Supports Magisk, KernelSU and APatch, no Zygisk, LSPosed or Meta Module required."

notify() {
    local TITLE="$1"
    local MSG="$2"
    local ICON="${3:-@android:drawable/ic_dialog_info}"
    local TAG="${4:-SFS_STATUS}"
    local SAFE_MSG=$(printf '%b' "$MSG" | sed "s/'/'\\\\''/g")
    su 2000 -c "cmd notification post -i '$ICON' -t '$TITLE' -S bigtext '$TAG' '$SAFE_MSG'" >/dev/null 2>&1 || \
    cmd notification post -i "$ICON" -t "$TITLE" -S bigtext "$TAG" "$SAFE_MSG" >/dev/null 2>&1
}

if [ -d "/data/adb/magisk" ] && magisk -V >/dev/null 2>&1; then
    ROOT="Magisk"
elif [ -d "/data/adb/ksu" ] && ksud -V >/dev/null 2>&1; then
    ROOT="KernelSU"
elif [ -d "/data/adb/ap" ] && apd -V >/dev/null 2>&1; then
    ROOT="APatch"
else
    ROOT="Unknown"
fi

MOD_JAR="$MODDIR/system/framework/services.jar"
SYS_JAR="/system/framework/services.jar"
if [ -f "$MOD_JAR" ] && cmp -s "$MOD_JAR" "$SYS_JAR" 2>/dev/null; then
    MOUNT_OK=true
    MOUNT_LABEL="OK"
else
    MOUNT_OK=false
    MOUNT_LABEL="FAIL"
fi

is_logging_active() {
    if [ -f "$LOGCAT_PID_FILE" ]; then
        local PID=$(cat "$LOGCAT_PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            return 0
        fi
        rm -f "$LOGCAT_PID_FILE"
    fi
    return 1
}

finalize_debug_log() {
    local PID=$(cat "$LOGCAT_PID_FILE" 2>/dev/null)
    [ -n "$PID" ] && kill -9 "$PID" 2>/dev/null
    rm -f "$LOGCAT_PID_FILE"
    killall getevent 2>/dev/null

    local DUMP_WIN=$(dumpsys window 2>/dev/null)
    local FOCUSED_PKG=$(echo "$DUMP_WIN" | grep -E 'mCurrentFocus|mFocusedApp' | grep -oE '[a-zA-Z0-9._]+/[a-zA-Z0-9._]+' | head -n 1 | cut -d/ -f1)

    if [ ! -f "$LOGCAT_TMP" ]; then
        logcat -d -t 3000 > "$LOGCAT_TMP" 2>/dev/null
    else
        logcat -d -t 300 >> "$LOGCAT_TMP" 2>/dev/null
    fi

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
        dumpsys activity recents 2>/dev/null | grep -E 'Recent #[0-4]:' | head -n 5
        echo "$DUMP_WIN" | grep -iE 'mHasSecure|isSecure|FLAG_SECURE|canBeScreenshotTarget|notAllowCaptureDisplay|hasSecure|isAllowedDisableScreenshot|shouldBlockScreenCapture' | head -n 25
        echo
        echo "--- [Window Policy & Screenshot Strategies] ---"
        dumpsys window policy 2>/dev/null | grep -iE 'screenshot|secure|Strategy|KeyCombination|mSafeMode|mSystemReady' | head -n 25
        echo

        awk -v pkg="$FOCUSED_PKG" '
        {
            line = $0
            llow = tolower(line)

            if (llow ~ /capturedisplay|notallowcapturedisplay|isalloweddisablescreenshot|accessscreencontent|timed out waiting for screenshot|flag_secure|issecurelocked|hassecure|blackscreenshot|sensitivecontent|shouldblockscreencapture/) {
                crit[cc++] = line
            }

            if (llow ~ /sfs|screenshot|globalscreenshot|screenshotcontroller|surfaceflinger.*capture/) {
                act[ac++] = line
            }

            if (pkg != "" && index(line, pkg) > 0) {
                if (llow ~ /window|secure|capture|screenshot|surface|flags|block|denied|timeout|null/) {
                    app[apc++] = line
                }
            }

            if (llow ~ /avc:.*denied|sfs.*fatal|dex2oat.*services\.jar/) {
                den[dc++] = line
            }
        }
        END {
            print "--- [Screenshot Decision & Gatekeeper Logs (Critical)] ---"
            start = (cc > 60) ? cc - 60 : 0
            for (i = start; i < cc; i++) print crit[i]
            print ""

            print "--- [Live Recorded Screenshot Activity (Context)] ---"
            start = (ac > 60) ? ac - 60 : 0
            for (i = start; i < ac; i++) print act[i]
            print ""

            if (pkg != "") {
                print "--- [Logs for Focused App: " pkg "] ---"
                start = (apc > 35) ? apc - 35 : 0
                for (i = start; i < apc; i++) print app[i]
                print ""
            }

            print "--- [System & SELinux Denials] ---"
            start = (dc > 25) ? dc - 25 : 0
            for (i = start; i < dc; i++) print den[i]
            print ""
        }
        ' "$LOGCAT_TMP" 2>/dev/null

        echo "=================================================="
        echo "Send this sfs_debug.log AND services.jar from Downloads to:"
        echo "👥 @BuildBytesDiscussion on Telegram"
        echo "🔗 https://telegram.me/BuildBytesDiscussion"
        echo "=================================================="
    } > "$LOG_FILE" 2>&1
    chmod 644 "$LOG_FILE" 2>/dev/null
    rm -f "$LOGCAT_TMP"

    local SAVED_PATH=""
    for d in "/sdcard/Download" "/storage/emulated/0/Download" "/sdcard" "/storage/emulated/0"; do
        if [ -d "$d" ]; then
            cp -f "$LOG_FILE" "$d/sfs_debug.log" 2>/dev/null
            chmod 666 "$d/sfs_debug.log" 2>/dev/null
            SAVED_PATH="$d/sfs_debug.log"
            cp -f "$SYS_JAR" "$d/services.jar" 2>/dev/null
            chmod 666 "$d/services.jar" 2>/dev/null
            break
        fi
    done

    echo "=================================================="
    echo "       Simple Flag Secure - Log Saved"
    echo "=================================================="
    echo "  ✅ Debug sfs_debug.log & services.jar saved successfully!"
    echo "  📁 Saved to Downloads folder:"
    echo "     • sfs_debug.log"
    echo "     • services.jar"
    echo "  👉 Please share BOTH files to @BuildBytesDiscussion"
    echo "=================================================="

    notify "✅ LOG SAVED • Simple Flag Secure" "sfs_debug.log & services.jar saved to Downloads! Please share BOTH files to @BuildBytesDiscussion." "@android:drawable/ic_menu_save" "SFS_STATUS"

    ( am start -a android.intent.action.VIEW -d "tg://resolve?domain=BuildBytesDiscussion" 2>/dev/null || \
      am start -a android.intent.action.VIEW -d https://telegram.me/BuildBytesDiscussion 2>/dev/null ) >/dev/null 2>&1 &
}

start_debug_logging() {
    logcat -c 2>/dev/null
    rm -f "$LOGCAT_TMP"
    ( logcat -v threadtime > "$LOGCAT_TMP" 2>&1 ) </dev/null >/dev/null 2>&1 &
    echo $! > "$LOGCAT_PID_FILE"

    echo "=================================================="
    echo "      Simple Flag Secure - Debug Logging"
    echo "=================================================="
    echo "  🔴 Recording Started!"
    echo "--------------------------------------------------    "
    echo "  1. Switch to your restricted app."
    echo "  2. Try taking a screenshot now."
    echo "  3. Press ANY button (Vol / Power) to save."
    echo "=================================================="
    echo "  ⏳ Listening for key press..."

    notify "📸 RECORDING • Simple Flag Secure" "Logging Active: Try screenshot in app, then press ANY button to save." "@android:drawable/ic_menu_camera" "SFS_STATUS"

    WATCH_KEY_LOG="/data/local/tmp/.sfs_watch_$$"
    rm -f "$WATCH_KEY_LOG"
    getevent -l > "$WATCH_KEY_LOG" 2>/dev/null &
    G_PID=$!

    ( sleep 300; kill -9 "$G_PID" 2>/dev/null; rm -f "$WATCH_KEY_LOG" ) </dev/null >/dev/null 2>&1 &
    TIMER_PID=$!

    while [ -f "$LOGCAT_PID_FILE" ]; do
        if [ -s "$WATCH_KEY_LOG" ]; then
            if grep -q 'KEY_.*DOWN' "$WATCH_KEY_LOG" 2>/dev/null; then
                break
            fi
        fi
        sleep 0.1
    done

    kill -9 "$G_PID" 2>/dev/null
    kill -9 "$TIMER_PID" 2>/dev/null
    killall getevent 2>/dev/null
    rm -f "$WATCH_KEY_LOG"

    echo ""
    echo "=================================================="
    echo "  ⏳ Recording stopped! Compiling diagnostic log..."
    echo "=================================================="

    notify "⏳ SAVING LOG • Simple Flag Secure" "Recording stopped! Compiling diagnostic log..." "@android:drawable/ic_menu_save" "SFS_STATUS"
    finalize_debug_log
}

if is_logging_active; then
    finalize_debug_log
    exit 0
fi

case "$1" in
  start_log|record|"log start")
    start_debug_logging
    exit 0
    ;;
  stop_log|"log stop"|debug)
    finalize_debug_log
    [ -t 1 ] && cat "$LOG_FILE" 2>/dev/null
    exit 0
    ;;
  status|STATUS)
    CURRENT=$(getprop persist.sys.sfs.screenshot)
    echo "Status: ${CURRENT:-true}"
    echo "Mount:  $MOUNT_LABEL"
    exit 0
    ;;
esac

if [ "$MOUNT_OK" != "true" ]; then
    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    echo "=================================================="
    echo "        Simple Flag Secure - Action"
    echo "=================================================="
    echo "  ❌ Mount Error: services.jar is NOT mounted!"
    echo "  Cannot toggle modes while module is inactive."
    echo "  Help: https://telegram.me/BuildBytesDiscussion"
    echo "=================================================="
    notify "Simple Flag Secure" "❌ services.jar is not mounted! Module is inactive."
    exit 1
fi

TARGET=""
case "$1" in
  allow|ALLOW|true|1) TARGET="true" ;;
  block|BLOCK|false|0) TARGET="false" ;;
  toggle|TOGGLE)
    CURRENT=$(getprop persist.sys.sfs.screenshot)
    [ "$CURRENT" = "false" ] && TARGET="true" || TARGET="false"
    ;;
esac

if [ -z "$TARGET" ]; then
    CURRENT=$(getprop persist.sys.sfs.screenshot)
    if [ "$CURRENT" = "false" ]; then
        CUR_STATUS="[ ❌ BLOCKED ]"
        VOL_UP_TEXT="Switch to ALLOWED (✅)"
    else
        CUR_STATUS="[ ✅ ALLOWED ]"
        VOL_UP_TEXT="Switch to BLOCKED (❌)"
    fi

    echo "=================================================="
    echo "        Simple Flag Secure - Action Menu"
    echo "=================================================="
    echo "  Current Mode: $CUR_STATUS"
    echo "  Mount Status: ✅ OK"
    echo "--------------------------------------------------"
    echo "  👉 Press a Volume Button within 30s:"
    echo "  [Vol +]  $VOL_UP_TEXT"
    echo "  [Vol -]  Start Debug Log Recording"
    echo "=================================================="

    KEY_LOG="/data/local/tmp/.sfs_menu_$$"
    rm -f "$KEY_LOG"
    getevent -l > "$KEY_LOG" 2>/dev/null &
    G_PID=$!

    COUNT=0
    CHOICE=""
    while [ "$COUNT" -lt 300 ]; do
        if [ -s "$KEY_LOG" ]; then
            if grep -q 'KEY_VOLUMEUP.*DOWN' "$KEY_LOG" 2>/dev/null; then
                CHOICE="UP"
                break
            elif grep -q 'KEY_VOLUMEDOWN.*DOWN' "$KEY_LOG" 2>/dev/null; then
                CHOICE="DOWN"
                break
            fi
        fi
        sleep 0.1
        COUNT=$((COUNT + 1))
    done

    kill -9 "$G_PID" 2>/dev/null
    killall getevent 2>/dev/null
    rm -f "$KEY_LOG"

    if [ "$CHOICE" = "DOWN" ]; then
        start_debug_logging
        exit 0
    elif [ "$CHOICE" = "UP" ]; then
        [ "$CURRENT" = "false" ] && TARGET="true" || TARGET="false"
    else
        echo "  ⏱️ Timeout: No volume key pressed in 30s. Exiting."
        exit 0
    fi
fi

if [ "$TARGET" = "true" ]; then
  STATUS="ALLOWED"
  ICON="✅"
  NOTIF_ICON="@android:drawable/ic_menu_view"
  DESC="Screenshots and recordings allowed everywhere"
else
  STATUS="BLOCKED"
  ICON="❌"
  NOTIF_ICON="@android:drawable/ic_menu_close_clear_cancel"
  DESC="Screenshots and recordings blocked everywhere - Privacy Mode"
fi

setprop persist.sys.sfs.screenshot "$TARGET"
sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null

echo "=================================================="
echo "        Simple Flag Secure - Action Toggle"
echo "=================================================="
echo "  Status: $ICON $STATUS"
echo "  Mount:  ✅ OK"
echo "  Prop:   persist.sys.sfs.screenshot = $TARGET"
echo "  Help:   https://telegram.me/BuildBytesDiscussion"
echo "--------------------------------------------------"
echo "  💡 Tip: If any secure app was already open, swipe it"
echo "     away from Recents & reopen to refresh its screen."
echo "--------------------------------------------------"
echo "  ⏳ Restarting SystemUI in 3 seconds to apply..."
echo "  (Screen will reload briefly, don't panic! 😊)"
echo "=================================================="

notify "$ICON $STATUS • Simple Flag Secure" "Switched to $STATUS: $DESC. Restarting SystemUI in 3s..." "$NOTIF_ICON" "SFS_STATUS"

sleep 3
killall com.android.systemui 2>/dev/null || pkill -f com.android.systemui 2>/dev/null || kill -9 $(pidof com.android.systemui) 2>/dev/null
