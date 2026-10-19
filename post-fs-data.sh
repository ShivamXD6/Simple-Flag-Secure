#!/system/bin/sh
MODDIR="${0%/*}"
if [ "$MODDIR" = "$0" ] || [ ! -f "$MODDIR/module.prop" ]; then
  MODDIR="/data/adb/modules/simple_flag_secure"
fi
PATCHED_JAR="$MODDIR/services.jar"
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

log_step "Setting SELinux context on patched jar..."
chcon --reference="$TARGET_JAR" "$PATCHED_JAR" >> "$LOG_FILE" 2>&1 || \
chcon u:object_r:system_file:s0 "$PATCHED_JAR" >> "$LOG_FILE" 2>&1

# Stage in /dev (already in-memory tmpfs) to eliminate /adb/ root token from mountinfo
STAGE_JAR="/dev/.sfs_services.jar"
cp -f "$PATCHED_JAR" "$STAGE_JAR" >> "$LOG_FILE" 2>&1
chcon --reference="$TARGET_JAR" "$STAGE_JAR" >> "$LOG_FILE" 2>&1 || \
chcon u:object_r:system_file:s0 "$STAGE_JAR" >> "$LOG_FILE" 2>&1

MOUNT_SRC="$STAGE_JAR"
[ -f "$MOUNT_SRC" ] || MOUNT_SRC="$PATCHED_JAR"

log_step "Executing mount from $MOUNT_SRC..."
mount -o bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
mount --bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
busybox mount -o bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1
MOUNT_RES=$?
log_step "Mount finished: $MOUNT_RES"

if cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
  log_step "VERIFIED: Mount active."
else
  log_step "WARNING: Mount check mismatch."
fi

# KernelSU stealth auto-umount for non-root processes
if [ -x /data/adb/ksud ]; then
  /data/adb/ksud kernel umount add "$TARGET_JAR" -f 2 >> "$LOG_FILE" 2>&1
elif which ksud >/dev/null 2>&1; then
  ksud kernel umount add "$TARGET_JAR" -f 2 >> "$LOG_FILE" 2>&1
fi

log_step "post-fs-data completed."
exit 0
