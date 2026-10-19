#!/system/bin/sh
MODDIR="${0%/*}"
PATCHED_JAR="$MODDIR/services.jar"
TARGET_JAR="/system/framework/services.jar"

LOG_FILE="$MODDIR/sfs_reboot.log"

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [reboot] $*" >> "$LOG_FILE"
}

# Resolve canonical paths if symlinked
REAL_TARGET="$(readlink -f "$TARGET_JAR" 2>/dev/null)"
[ -f "$REAL_TARGET" ] && TARGET_JAR="$REAL_TARGET"
REAL_PATCHED="$(readlink -f "$PATCHED_JAR" 2>/dev/null)"
[ -f "$REAL_PATCHED" ] && PATCHED_JAR="$REAL_PATCHED"

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

# Stage in clean tmpfs to eliminate /adb/ root token from mountinfo

log_step "Setting SELinux context on patched jar..."
chcon --reference="$TARGET_JAR" "$PATCHED_JAR" >> "$LOG_FILE" 2>&1 || \
chcon u:object_r:system_file:s0 "$PATCHED_JAR" >> "$LOG_FILE" 2>&1

# Stage in clean tmpfs to eliminate /adb/ root token from mountinfo
STAGING_DIR="/dev/.sfs_stage"
mkdir -p "$STAGING_DIR" 2>/dev/null
mount -t tmpfs -o size=64M,mode=0755 tmpfs "$STAGING_DIR" 2>/dev/null
cp -f "$PATCHED_JAR" "$STAGING_DIR/services.jar" 2>/dev/null
chcon --reference="$TARGET_JAR" "$STAGING_DIR/services.jar" 2>/dev/null || \
chcon u:object_r:system_file:s0 "$STAGING_DIR/services.jar" 2>/dev/null

MOUNT_SRC="$STAGING_DIR/services.jar"
[ -f "$MOUNT_SRC" ] || MOUNT_SRC="$PATCHED_JAR"

log_step "Executing mount..."
mount -o bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
mount --bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
busybox mount -o bind "$MOUNT_SRC" "$TARGET_JAR" >> "$LOG_FILE" 2>&1
MOUNT_RES=$?
log_step "Mount finished: $MOUNT_RES"

# Lazy unmount staging mountpoint (bind mount on TARGET_JAR stays intact)
umount -l "$STAGING_DIR" 2>/dev/null
rmdir "$STAGING_DIR" 2>/dev/null

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
