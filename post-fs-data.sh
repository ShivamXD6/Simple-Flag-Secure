#!/system/bin/sh
MODDIR="${0%/*}"
PATCHED_JAR="$MODDIR/services.jar"
[ -f "$PATCHED_JAR" ] || PATCHED_JAR="$MODDIR/system/framework/services.jar"
TARGET_JAR="/system/framework/services.jar"

LOG_FILE="$MODDIR/sfs_reboot.log"

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [reboot] $*" >> "$LOG_FILE"
}

{
  echo "=================================================="
  echo "       SFS Reboot Log"
  echo "=================================================="
  echo "Time: $(date)"
  echo "MODDIR: $MODDIR"
  echo "PATCHED_JAR: $PATCHED_JAR (exists: $([ -f "$PATCHED_JAR" ] && echo "YES, $(wc -c < "$PATCHED_JAR" 2>/dev/null) bytes" || echo "NO"))"
  echo "TARGET_JAR: $TARGET_JAR (exists: $([ -f "$TARGET_JAR" ] && echo "YES, $(wc -c < "$TARGET_JAR" 2>/dev/null) bytes" || echo "NO"))"
  echo "--------------------------------------------------"
} > "$LOG_FILE" 2>&1

[ -f "$PATCHED_JAR" ] || {
  log_step "FAIL: Patched jar does not exist at $PATCHED_JAR"
  exit 0
}

# Detect Root Solution
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

log_step "Detected Root Manager: $ROOT"

# Meta-Module
HAS_METAMODULE=false
if [ -d "$ADBDIR/metamodule" ]; then
  HAS_METAMODULE=true
fi

# Mount check
if { [ "$ROOT" = "Magisk" ] || [ "$HAS_METAMODULE" = "true" ]; } && cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
  log_step "OverlayFS / Magic Mount / Meta-Module already mounted patched jar. Skipping manual bind mount."
  exit 0
fi

log_step "Setting SELinux context on patched jar..."
chcon --reference="$TARGET_JAR" "$PATCHED_JAR" >> "$LOG_FILE" 2>&1

SUSFS_BIN=""
if [ -x /data/adb/ksu/bin/ksu_susfs ]; then
  SUSFS_BIN="/data/adb/ksu/bin/ksu_susfs"
elif [ -x /data/adb/ap/bin/ksu_susfs ]; then
  SUSFS_BIN="/data/adb/ap/bin/ksu_susfs"
elif which ksu_susfs >/dev/null 2>&1; then
  SUSFS_BIN="ksu_susfs"
fi

if [ -n "$SUSFS_BIN" ]; then
  "$SUSFS_BIN" add_sus_kstat "$TARGET_JAR" >> "$LOG_FILE" 2>&1
fi

log_step "Executing mount..."
mount -o bind "$PATCHED_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1
MOUNT_RES=$?
log_step "Mount finished: $MOUNT_RES"

if cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
  log_step "VERIFIED: Mount active."
else
  log_step "WARNING: Mount check mismatch."
fi

if [ -n "$SUSFS_BIN" ]; then
  "$SUSFS_BIN" update_sus_kstat "$TARGET_JAR" >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" add_sus_path "$TARGET_JAR" >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" add_sus_path "$PATCHED_JAR" >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" hide_sus_mnts_for_non_su_procs 1 >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" add_try_umount "$TARGET_JAR" 1 >> "$LOG_FILE" 2>&1
fi

log_step "post-fs-data completed."
exit 0
