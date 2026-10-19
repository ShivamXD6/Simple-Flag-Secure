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

# 1. Attempt stealth staging in /dev (bypasses mountinfo /adb/ token detectors on supported devices)
STAGE_JAR="/dev/.sfs_services.jar"
MOUNT_OK=false

if cp -f "$PATCHED_JAR" "$STAGE_JAR" >> "$LOG_FILE" 2>&1; then
  chcon --reference="$TARGET_JAR" "$STAGE_JAR" >> "$LOG_FILE" 2>&1 || \
  chcon u:object_r:system_file:s0 "$STAGE_JAR" >> "$LOG_FILE" 2>&1

  log_step "Attempting stealth mount from $STAGE_JAR..."
  if mount -o bind "$STAGE_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
     mount --bind "$STAGE_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
     busybox mount -o bind "$STAGE_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1; then
    if cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
      MOUNT_OK=true
      log_step "VERIFIED: Stealth mount active."
    fi
  fi
fi

# 2. Fallback to direct bind mount if stealth staging failed or was blocked by kernel (e.g. Samsung Knox)
if [ "$MOUNT_OK" != "true" ]; then
  rm -f "$STAGE_JAR" 2>/dev/null
  log_step "Stealth staging blocked or failed. Falling back to direct bind mount from $PATCHED_JAR..."
  mount -o bind "$PATCHED_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
  mount --bind "$PATCHED_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1 || \
  busybox mount -o bind "$PATCHED_JAR" "$TARGET_JAR" >> "$LOG_FILE" 2>&1
  MOUNT_RES=$?
  log_step "Direct mount finished: $MOUNT_RES"

  if cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
    MOUNT_OK=true
    log_step "VERIFIED: Direct mount active."
  else
    log_step "WARNING: Mount check mismatch after direct mount."
  fi
fi

# 3. KernelSU stealth auto-umount for non-root processes
if [ -x /data/adb/ksud ]; then
  /data/adb/ksud kernel umount add "$TARGET_JAR" -f 2 >> "$LOG_FILE" 2>&1
elif which ksud >/dev/null 2>&1; then
  ksud kernel umount add "$TARGET_JAR" -f 2 >> "$LOG_FILE" 2>&1
fi

# 4. SusFS stealth hiding if available
SUSFS_BIN=""
if [ -x /data/adb/ksu/bin/ksu_susfs ]; then
  SUSFS_BIN="/data/adb/ksu/bin/ksu_susfs"
elif [ -x /data/adb/ap/bin/ksu_susfs ]; then
  SUSFS_BIN="/data/adb/ap/bin/ksu_susfs"
elif which ksu_susfs >/dev/null 2>&1; then
  SUSFS_BIN="ksu_susfs"
fi

if [ -n "$SUSFS_BIN" ]; then
  "$SUSFS_BIN" add_sus_path "$TARGET_JAR" >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" add_sus_path "$PATCHED_JAR" >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" hide_sus_mnts_for_non_su_procs 1 >> "$LOG_FILE" 2>&1
  "$SUSFS_BIN" add_try_umount "$TARGET_JAR" 1 >> "$LOG_FILE" 2>&1
fi

log_step "post-fs-data completed."
exit 0
