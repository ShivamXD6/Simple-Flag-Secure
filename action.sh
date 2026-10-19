#!/system/bin/sh
MODDIR="${0%/*}"
[ "$MODDIR" = "$0" ] && MODDIR="."
if [ "$MODDIR" = "." ] || [ ! -f "$MODDIR/module.prop" ]; then
    MODDIR="/data/adb/modules/simple_flag_secure"
fi
LOG_FILE="$MODDIR/sfs_debug.log"
LOGCAT_PID_FILE="$MODDIR/.logcat.pid"
LOGCAT_TMP="$MODDIR/.logcat_recording.tmp"

BASE_DESC="Bypasses screenshot restrictions and hides screenshot detection."

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

MOD_JAR="$MODDIR/services.jar"
SYS_JAR="/system/framework/services.jar"
if [ -f "$MOD_JAR" ] && cmp -s "$MOD_JAR" "$SYS_JAR" 2>/dev/null; then
    MOUNT_OK=true
    MOUNT_LABEL="OK"
else
    MOUNT_OK=false
    MOUNT_LABEL="FAIL"
fi

update_module_desc() {
    if [ "$MOUNT_OK" = "true" ]; then
        local CUR=$(getprop persist.sys.sfs.screenshot)
        local ST="ALLOWED"
        local IC="✅"
        if [ "$CUR" = "false" ]; then
            ST="BLOCKED"
            IC="❌"
        fi
        sed -i "s#^description=.*#description=[ $IC $ST ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    else
        sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
    fi
}
update_module_desc

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

    if [ ! -f "$LOGCAT_TMP" ] || [ ! -s "$LOGCAT_TMP" ]; then
        logcat -d -t 1500 > "$LOGCAT_TMP" 2>/dev/null
    fi

    {
        echo "--- Simple Flag Secure - Diagnostic Log ---"
        echo "Time: $(date)"
        echo "Module Version: $(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "ROM Build: $(getprop ro.build.display.id)"
        echo "SELinux: $(getenforce 2>/dev/null)"
        echo "Root Manager: $ROOT"
        echo ""
        echo "--- services.jar Mount Check ---"
        echo "Stock JAR:   $SYS_JAR"
        echo "Module JAR:  $MOD_JAR"
        if [ "$MOUNT_OK" = "true" ]; then
            echo "Mount Status: [OK] Patched services.jar is mounted!"
        else
            echo "Mount Status: [FAIL] services.jar is NOT mounted or differs from module!"
        fi
        echo ""
        echo "--- Active Mounts ---"
        grep 'services.jar' /proc/mounts 2>/dev/null || echo "No direct bind mounts found for services.jar"
        echo "--- SFS Properties ---"
        echo "persist.sys.sfs.screenshot: $(getprop persist.sys.sfs.screenshot)"
        echo ""
        echo "--- Window Focus & Secure State ---"
        echo "$DUMP_WIN" | grep -E 'mCurrentFocus|mFocusedApp' | head -n 5
        echo "$DUMP_WIN" | grep -iE 'mHasSecure|isSecure|FLAG_SECURE|canBeScreenshotTarget|notAllowCaptureDisplay|hasSecure|isAllowedDisableScreenshot|shouldBlockScreenCapture' | head -n 25
        echo ""
        echo "--- Window Policy Details ---"
        echo "$DUMP_WIN" | grep -iE 'screenshot|secure|Strategy|KeyCombination|mSafeMode|mSystemReady' | head -n 25
        echo ""

        awk -v pkg="$FOCUSED_PKG" '
        BEGIN {
            MAX_CRIT = 50; MAX_ACT = 50; MAX_APP = 30; MAX_DEN = 20
        }
        {
            line = $0
            l = tolower(line)

            if (l ~ /capturedisplay|notallowcapturedisplay|isalloweddisablescreenshot|accessscreencontent|timed out waiting|flag_secure|issecurelocked|hassecure|blackscreenshot|sensitivecontent|shouldblockscreencapture/) {
                crit[cc % MAX_CRIT] = line; cc++
            } else if (l ~ /sfs|screenshot|globalscreenshot|screenshotcontroller|surfaceflinger.*capture/) {
                act[ac % MAX_ACT] = line; ac++
            }

            if (pkg != "" && index(line, pkg) > 0 && l ~ /window|secure|capture|screenshot|surface|flags|block|denied/) {
                app[apc % MAX_APP] = line; apc++
            }

            if (l ~ /avc:.*denied|dex2oat.*services\.jar/) {
                den[dc % MAX_DEN] = line; dc++
            }
        }
        function print_ring(arr, total, max_sz, title) {
            if (total == 0) return
            print "--- " title " ---"
            n = (total < max_sz) ? total : max_sz
            s = (total < max_sz) ? 0 : (total % max_sz)
            for (i = 0; i < n; i++) print arr[(s + i) % max_sz]
            print ""
        }
        END {
            print_ring(crit, cc, MAX_CRIT, "Critical Screenshot Decision Logs")
            print_ring(act, ac, MAX_ACT, "Screenshot Context & Actions")
            if (pkg != "") print_ring(app, apc, MAX_APP, "Focused App Logs: " pkg)
            print_ring(den, dc, MAX_DEN, "SELinux & System Denials")
        }
        ' "$LOGCAT_TMP" 2>/dev/null

        echo "--- Support ---"
        echo "Telegram: @BuildBytesDiscussion (https://telegram.me/BuildBytesDiscussion)"
    } > "$LOG_FILE" 2>&1
    chmod 644 "$LOG_FILE" 2>/dev/null
    rm -f "$LOGCAT_TMP"

    # Export report
    local MERGED_LOG="$MODDIR/sfs.log"
    {
        echo "=== Simple Flag Secure - Unified Log Report ==="
        echo "Generated: $(date)"
        echo "Version: $(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "Root Manager: $ROOT"
        echo ""

        echo "--- Section 1: Installation Log (sfs_install.log) ---"
        if [ -f "$MODDIR/sfs_install.log" ]; then
            cat "$MODDIR/sfs_install.log"
        else
            echo "sfs_install.log not found."
        fi
        echo ""

        echo "--- Section 2: Reboot / Mount Log (sfs_reboot.log) ---"
        if [ -f "$MODDIR/sfs_reboot.log" ]; then
            cat "$MODDIR/sfs_reboot.log"
        elif [ -f "$MODDIR/post-fs-data.log" ]; then
            cat "$MODDIR/post-fs-data.log"
        else
            echo "sfs_reboot.log not found."
        fi
        echo ""

        echo "--- Section 3: Diagnostic Log (sfs_debug.log) ---"
        cat "$LOG_FILE" 2>/dev/null || echo "sfs_debug.log not found."
        echo ""
    } > "$MERGED_LOG" 2>&1
    chmod 644 "$MERGED_LOG" 2>/dev/null

    local TARGET_JAR="$SYS_JAR"
    [ -f "$TARGET_JAR" ] || TARGET_JAR="$MOD_JAR"

    # Package archive
    local STAGE_DIR="/data/local/tmp/.sfs_stage_$$"
    local REPORT_PKG="/data/local/tmp/sfs_report.tar.gz"
    rm -rf "$STAGE_DIR" "$REPORT_PKG" 2>/dev/null
    mkdir -p "$STAGE_DIR" 2>/dev/null
    cp -f "$MERGED_LOG" "$STAGE_DIR/sfs.log" 2>/dev/null
    [ -f "$TARGET_JAR" ] && cp -f "$TARGET_JAR" "$STAGE_DIR/services.jar" 2>/dev/null

    ( cd "$STAGE_DIR" && tar -cf - * 2>/dev/null | gzip -1 > "$REPORT_PKG" ) 2>/dev/null || \
    ( cd "$STAGE_DIR" && tar -czf "$REPORT_PKG" * 2>/dev/null )
    rm -rf "$STAGE_DIR" 2>/dev/null

    for d in "/sdcard/Download" "/storage/emulated/0/Download" "/sdcard" "/storage/emulated/0"; do
        if [ -d "$d" ]; then
            cp -f "$REPORT_PKG" "$d/sfs_report.tar.gz" 2>/dev/null
            chmod 666 "$d/sfs_report.tar.gz" 2>/dev/null
            cp -f "$MERGED_LOG" "$d/sfs.log" 2>/dev/null
            chmod 666 "$d/sfs.log" 2>/dev/null
            break
        fi
    done

    echo "=================================================="
    echo "       Simple Flag Secure - Log Saved"
    echo "=================================================="
    echo "  ✅ Unified sfs_report.tar.gz created successfully!"
    echo "  📁 Saved to Downloads folder:"
    echo "     • sfs_report.tar.gz (sfs.log + services.jar)"
    echo "     • sfs.log"
    echo "  👉 Please share sfs_report.tar.gz to @BuildBytesDiscussion"
    echo "=================================================="

    # Dispatch intent
    send_bugreport() {
        local PKG_SRC="$1"
        local BUGREPORT_DIR="/data/user_de/0/com.android.shell/files/bugreports"
        mkdir -p "$BUGREPORT_DIR" 2>/dev/null

        cp -f "$PKG_SRC" "$BUGREPORT_DIR/sfs_report.tar.gz" 2>/dev/null
        chmod 666 "$BUGREPORT_DIR/sfs_report.tar.gz" 2>/dev/null
        chown 2000:2000 "$BUGREPORT_DIR/sfs_report.tar.gz" 2>/dev/null
        chcon u:object_r:shell_data_file:s0 "$BUGREPORT_DIR/sfs_report.tar.gz" 2>/dev/null
        rm -f "$PKG_SRC" 2>/dev/null

        su 2000 -c "am start -a android.intent.action.SEND --eu android.intent.extra.STREAM content://com.android.shell/bugreports/sfs_report.tar.gz -t '*/*' --grant-read-uri-permission" >/dev/null 2>&1 || \
        am start -a android.intent.action.SEND --eu android.intent.extra.STREAM content://com.android.shell/bugreports/sfs_report.tar.gz -t '*/*' --grant-read-uri-permission >/dev/null 2>&1

        notify "📤 Share to @BuildBytesDiscussion" "Please send sfs_report.tar.gz to @BuildBytesDiscussion group!" "@android:drawable/ic_dialog_info" "SFS_STATUS"
    }

    ( send_bugreport "$REPORT_PKG" ) >/dev/null 2>&1 &
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
    if [ "$MOUNT_OK" != "true" ]; then
        notify "⚠️ Warning • Simple Flag Secure" "services.jar not mounted! Use Vol - to export logs." "@android:drawable/ic_dialog_alert" "SFS_WARN"
    fi

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
    if [ "$MOUNT_OK" = "true" ]; then
        echo "  Mount Status: ✅ OK"
    else
        echo "  Mount Status: ⚠️ FAIL"
        if [ ! -f "$MODDIR/sfs_reboot.log" ]; then
            echo "  ⚠️ Notice: Device was NOT rebooted after install!"
            echo "     Please do a FULL REBOOT (not soft reboot)."
        else
            echo "  ⚠️ Warning: services.jar not mounted! Press [Vol -] to export logs."
        fi
    fi
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
setprop persist.wm.debug.sfs.screenshot "$TARGET" 2>/dev/null

if [ "$MOUNT_OK" != "true" ]; then
    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
else
    sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
fi

echo "=================================================="
echo "        Simple Flag Secure - Action Toggle"
echo "=================================================="
echo "  Status: $ICON $STATUS"
if [ "$MOUNT_OK" = "true" ]; then
    echo "  Mount:  ✅ OK"
else
    echo "  Mount:  ⚠️ FAIL (services.jar not mounted)"
    echo "  ⚠️ Warning: services.jar not mounted!"
fi
echo "  Prop:   persist.sys.sfs.screenshot = $TARGET"
echo "  Help:   https://telegram.me/BuildBytesDiscussion"
echo "--------------------------------------------------"
echo "  ⏳ Restarting SystemUI in 5 seconds to apply..."
echo "  (Screen will reload briefly, don't panic! 😊)"
echo "=================================================="

if [ "$MOUNT_OK" != "true" ]; then
    notify "⚠️ $STATUS • Simple Flag Secure" "⚠️ services.jar not mounted! Switched to $STATUS. Restarting SystemUI in 5s..." "@android:drawable/stat_notify_error" "SFS_STATUS"
else
    notify "$ICON $STATUS • Simple Flag Secure" "Switched to $STATUS: $DESC. Restarting SystemUI in 5s..." "$NOTIF_ICON" "SFS_STATUS"
fi

sleep 5
killall com.android.systemui 2>/dev/null || pkill -f com.android.systemui 2>/dev/null || kill -9 $(pidof com.android.systemui) 2>/dev/null
