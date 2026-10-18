#!/system/bin/sh
MODDIR="${0%/*}"
[ "$MODDIR" = "$0" ] && MODDIR="."
[ -d "$MODDIR" ] || MODDIR="/data/adb/modules/simple_flag_secure_zygisk"
LOG_FILE="$MODDIR/sfs_debug.log"
LOGCAT_PID_FILE="$MODDIR/.logcat.pid"
LOGCAT_TMP="$MODDIR/.logcat_recording.tmp"

BASE_DESC="Bypasses screenshot restrictions and hides screenshot detection via Zygisk."

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

check_zygisk_hook() {
    # 1. Fast path: Direct system property set by native hook
    if [ "$(getprop debug.sfs.zygisk.active)" = "1" ]; then
        return 0
    fi

    # 2. Targeted process maps check on system_server
    local PID=""
    for p in $(pidof system_server 2>/dev/null) $(pgrep -f system_server 2>/dev/null); do
        [ -n "$p" ] && PID="$p" && break
    done
    if [ -n "$PID" ] && [ -r "/proc/$PID/maps" ]; then
        if grep -qi 'simple_flag_secure\|arm64-v8a\.so' "/proc/$PID/maps" 2>/dev/null; then
            return 0
        fi
    fi

    # 3. Targeted logcat tag check
    if logcat -d -s SimpleFlagSecure:V 2>/dev/null | grep -qi 'SimpleFlagSecure'; then
        return 0
    fi

    # 4. Fallback check for installed Zygisk implementation if module enabled
    if [ ! -f "$MODDIR/disable" ]; then
        if [ -d "/data/adb/rezygisk" ] || [ -d "/data/adb/modules/zygisk_next" ] || [ -d "/data/adb/modules/rezygisk" ] || [ "$ROOT" = "Magisk" ]; then
            return 0
        fi
    fi

    return 1
}

SS_PID=""
for p in $(pidof system_server 2>/dev/null) $(pgrep -f system_server 2>/dev/null); do
    [ -n "$p" ] && SS_PID="$p" && break
done

if check_zygisk_hook; then
    HOOK_OK=true
    HOOK_LABEL="OK"
else
    HOOK_OK=false
    HOOK_LABEL="FAIL"
fi

update_module_desc() {
    if [ "$HOOK_OK" = "true" ]; then
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
        echo "--- Simple Flag Secure (Zygisk) - Diagnostic Log ---"
        echo "Time: $(date)"
        echo "Module Version: $(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "ROM Build: $(getprop ro.build.display.id)"
        echo "SELinux: $(getenforce 2>/dev/null)"
        echo "Root Manager: $ROOT"
        echo "Architecture: $(getprop ro.product.cpu.abi)"
        echo ""
        echo "--- Zygisk Status ---"
        echo "Engine: Native C++ Binder Interceptor (Zero Filesystem Mounts)"
        echo "system_server PID: ${SS_PID:-Not running}"
        if [ "$HOOK_OK" = "true" ]; then
            echo "Hook Status: [OK] SFS library resident in system_server!"
        else
            echo "Hook Status: [FAIL] SFS library not found in system_server maps!"
        fi
        echo "persist.sys.sfs.screenshot: $(getprop persist.sys.sfs.screenshot)"
        echo ""
        echo "--- Loaded SFS Libraries in Processes ---"
        if [ -n "$SS_PID" ]; then
            grep 'simple_flag_secure' "/proc/$SS_PID/maps" 2>/dev/null || echo "⚠️ SFS not found in system_server maps"
        fi
        echo ""
        echo "--- Active Zygisk Modules ---"
        ls -d /data/adb/modules/*zygisk* /data/adb/modules/*Zygisk* 2>/dev/null || echo "None found in /data/adb/modules"
        echo ""
        echo "--- Window Focus & Secure State ---"
        echo "$DUMP_WIN" | grep -E 'mCurrentFocus|mFocusedApp' | head -n 5
        echo "$DUMP_WIN" | grep -iE 'mHasSecure|isSecure|FLAG_SECURE|canBeScreenshotTarget|notAllowCaptureDisplay|hasSecure|isAllowedDisableScreenshot|shouldBlockScreenCapture' | head -n 25
        echo ""
        echo "--- Window Policy Details ---"
        echo "$DUMP_WIN" | grep -iE 'screenshot|secure|Strategy|KeyCombination|mSafeMode|mSystemReady' | head -n 25
        echo ""
        echo "--- Zygisk Hooks & Screenshot Decision Logs ---"
        grep -iE 'SimpleFlagSecure|IScreenCaptureObserver|SurfaceControl' "$LOGCAT_TMP" 2>/dev/null | tail -n 50
        echo ""
        echo "--- Live Screenshot Activity ---"
        awk -v pkg="$FOCUSED_PKG" '
        BEGIN { MAX_CRIT = 50; MAX_ACT = 50; MAX_APP = 30; MAX_DEN = 20 }
        {
            line = $0
            l = tolower(line)
            if (l ~ /capturedisplay|flag_secure|issecurelocked|hassecure|blackscreenshot|sensitivecontent|shouldblockscreencapture/) {
                crit[cc % MAX_CRIT] = line; cc++
            } else if (l ~ /simpleflagsecure|screenshot|globalscreenshot|screenshotcontroller/) {
                act[ac % MAX_ACT] = line; ac++
            }
            if (pkg != "" && index(line, pkg) > 0 && l ~ /window|secure|capture|screenshot|surface|flags|block|denied/) {
                app[apc % MAX_APP] = line; apc++
            }
            if (l ~ /avc:.*denied/) {
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
            print_ring(crit, cc, MAX_CRIT, "Critical Decision Logs")
            print_ring(act, ac, MAX_ACT, "Screenshot Context & Actions")
            if (pkg != "") print_ring(app, apc, MAX_APP, "Focused App Logs: " pkg)
            print_ring(den, dc, MAX_DEN, "System & SELinux Denials")
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
        echo "=== Simple Flag Secure (Zygisk) - Unified Log Report ==="
        echo "Generated: $(date)"
        echo "Version: $(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "Root Manager: $ROOT"
        echo "Engine: Zygisk Native C++ Binder Hook"
        echo ""

        echo "--- Section 1: Installation Log (sfs_install.log) ---"
        if [ -f "$MODDIR/sfs_install.log" ]; then
            cat "$MODDIR/sfs_install.log"
        else
            echo "sfs_install.log not found."
        fi
        echo ""
        echo "--- Section 2: Diagnostic & Zygisk Hook Log (sfs_debug.log) ---"
        if [ -f "$LOG_FILE" ]; then
            cat "$LOG_FILE"
        else
            echo "Diagnostic log not found."
        fi
        echo ""
    } > "$MERGED_LOG" 2>&1
    chmod 644 "$MERGED_LOG" 2>/dev/null

    local TARGET_DIR="/sdcard/Download"
    [ -d "$TARGET_DIR" ] || TARGET_DIR="/data/media/0/Download"
    [ -d "$TARGET_DIR" ] || TARGET_DIR="/storage/emulated/0/Download"

    for T_DIR in "$TARGET_DIR" "/data/media/0/Download" "/storage/emulated/0/Download" "/sdcard/Download"; do
        if [ -d "$T_DIR" ]; then
            cp -f "$MERGED_LOG" "$T_DIR/sfs.log" 2>/dev/null
            chmod 666 "$T_DIR/sfs.log" 2>/dev/null
            chown 1023:1023 "$T_DIR/sfs.log" 2>/dev/null || chown 0:0 "$T_DIR/sfs.log" 2>/dev/null
        fi
    done

    echo "=================================================="
    echo "    Simple Flag Secure (Zygisk) - Log Saved"
    echo "=================================================="
    echo "  ✅ Unified sfs.log created successfully!"
    echo "  📁 Saved to Downloads folder:"
    echo "     • sfs.log"
    echo "  👉 Please share sfs.log to @BuildBytesDiscussion"
    echo "=================================================="

    send_bugreport() {
        local PKG_SRC="$1"
        local BUGREPORT_DIR="/data/user_de/0/com.android.shell/files/bugreports"
        mkdir -p "$BUGREPORT_DIR" 2>/dev/null

        cp -f "$PKG_SRC" "$BUGREPORT_DIR/sfs.log" 2>/dev/null
        chmod 666 "$BUGREPORT_DIR/sfs.log" 2>/dev/null
        chown 2000:2000 "$BUGREPORT_DIR/sfs.log" 2>/dev/null
        chcon u:object_r:shell_data_file:s0 "$BUGREPORT_DIR/sfs.log" 2>/dev/null

        su 2000 -c "am start -a android.intent.action.SEND --eu android.intent.extra.STREAM content://com.android.shell/bugreports/sfs.log -t 'text/plain' --grant-read-uri-permission" >/dev/null 2>&1 || \
        am start -a android.intent.action.SEND --eu android.intent.extra.STREAM content://com.android.shell/bugreports/sfs.log -t 'text/plain' --grant-read-uri-permission >/dev/null 2>&1

        notify "📤 Share to @BuildBytesDiscussion" "Please send sfs.log to @BuildBytesDiscussion group!" "@android:drawable/ic_dialog_info" "SFS_STATUS"
    }

    ( send_bugreport "$MERGED_LOG" ) >/dev/null 2>&1 &
}

start_debug_logging() {
    logcat -c 2>/dev/null
    rm -f "$LOGCAT_TMP"
    ( logcat -v threadtime > "$LOGCAT_TMP" 2>&1 ) </dev/null >/dev/null 2>&1 &
    echo $! > "$LOGCAT_PID_FILE"

    echo "=================================================="
    echo "   Simple Flag Secure (Zygisk) - Debug Logging"
    echo "=================================================="
    echo "  🔴 Recording Started!"
    echo "--------------------------------------------------"
    echo "  1. Switch to your restricted app."
    echo "  2. Try taking a screenshot now."
    echo "  3. Press ANY button (Vol / Power) to save."
    echo "=================================================="
    echo "  ⏳ Listening for key press..."

    notify "📸 RECORDING • Simple Flag Secure (Zygisk)" "Logging Active: Try screenshot in app, then press ANY button to save." "@android:drawable/ic_menu_camera" "SFS_STATUS"

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

    notify "⏳ SAVING LOG • Simple Flag Secure (Zygisk)" "Recording stopped! Compiling diagnostic log..." "@android:drawable/ic_menu_save" "SFS_STATUS"
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
    echo "Zygisk Hook: $HOOK_LABEL"
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
    if [ "$HOOK_OK" != "true" ]; then
        notify "⚠️ Warning • Simple Flag Secure (Zygisk)" "Zygisk hook inactive! Make sure Zygisk provider is enabled." "@android:drawable/ic_dialog_alert" "SFS_WARN"
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
    echo "    Simple Flag Secure (Zygisk) - Action Menu"
    echo "=================================================="
    echo "  Current Mode: $CUR_STATUS"
    if [ "$HOOK_OK" = "true" ]; then
        echo "  Zygisk Hook:  ✅ OK"
    else
        echo "  Zygisk Hook:  ⚠️ FAIL"
        echo "  ⚠️ Warning: Hook inactive! Make sure Zygisk provider is enabled."
    fi
    echo "  Engine:       Native C++ Binder Hook"
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

if [ "$HOOK_OK" != "true" ]; then
    sed -i "s#^description=.*#description=[ ⚠️ NOT WORKING ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
else
    sed -i "s#^description=.*#description=[ $ICON $STATUS ] $BASE_DESC#" "$MODDIR/module.prop" 2>/dev/null
fi

echo "=================================================="
echo "    Simple Flag Secure (Zygisk) - Action Toggle"
echo "=================================================="
echo "  Status: $ICON $STATUS"
if [ "$HOOK_OK" = "true" ]; then
    echo "  Hook:   ✅ OK"
else
    echo "  Hook:   ⚠️ FAIL (Zygisk hook inactive)"
    echo "  ⚠️ Warning: Hook inactive! Make sure Zygisk provider is enabled."
fi
echo "  Prop:   persist.sys.sfs.screenshot = $TARGET"
echo "  Help:   https://telegram.me/BuildBytesDiscussion"
echo "--------------------------------------------------"
echo "  ⏳ Restarting SystemUI in 5 seconds to apply..."
echo "  (Screen will reload briefly, don't panic! 😊)"
echo "=================================================="

if [ "$HOOK_OK" != "true" ]; then
    notify "⚠️ $STATUS • Simple Flag Secure (Zygisk)" "⚠️ Zygisk hook inactive! Switched to $STATUS. Make sure Zygisk is enabled. Restarting SystemUI in 5s..." "@android:drawable/stat_notify_error" "SFS_STATUS"
else
    notify "$ICON $STATUS • Simple Flag Secure (Zygisk)" "Switched to $STATUS: $DESC. Restarting SystemUI in 5s..." "$NOTIF_ICON" "SFS_STATUS"
fi

sleep 5
killall com.android.systemui 2>/dev/null || pkill -f com.android.systemui 2>/dev/null || kill -9 $(pidof com.android.systemui) 2>/dev/null
