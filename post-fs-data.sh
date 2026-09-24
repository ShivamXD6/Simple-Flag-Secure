#!/system/bin/sh
MODDIR="${0%/*}"
PATCHED_JAR="$MODDIR/system/framework/services.jar"
TARGET_JAR="/system/framework/services.jar"

# Exit if no patched jar
[ -f "$PATCHED_JAR" ] || exit 0

# Skip if already mounted
if cmp -s "$PATCHED_JAR" "$TARGET_JAR" 2>/dev/null; then
  exit 0
fi

# Fallback mount
mount --make-rshared / 2>/dev/null
chcon --reference="$TARGET_JAR" "$PATCHED_JAR" 2>/dev/null

# SusFS spoofing
[ -x /data/adb/ksu/bin/ksu_susfs ] && /data/adb/ksu/bin/ksu_susfs add_sus_kstat "$TARGET_JAR" 2>/dev/null

# Bind mount
mount -o bind "$PATCHED_JAR" "$TARGET_JAR"

# Hide mounts
if [ -x /data/adb/ksu/bin/ksu_susfs ]; then
  /data/adb/ksu/bin/ksu_susfs update_sus_kstat "$TARGET_JAR" 2>/dev/null
  /data/adb/ksu/bin/ksu_susfs add_try_umount "$TARGET_JAR" 1 >/dev/null 2>&1
fi
if [ -x /data/adb/ksud ]; then
  /data/adb/ksud kernel umount add "$TARGET_JAR" --flags 2 >/dev/null 2>&1
fi

exit 0
