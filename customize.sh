#!/system/bin/sh

# Abort in Recovery
if ! $BOOTMODE; then
  ui_print " ! Only uninstall is supported in recovery"
  sleep 1
  ui_print " - Uninstalling Simple Flag Secure!"
  sleep 1
  ui_print " - You can report me @ShastikXD if the module gave bootloop"
  sleep 1
  touch $MODPATH/remove
  rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
  exit 0
fi

# Fix backslash path
if [ -f "$MODPATH/system\\bin\\patcher.jar" ]; then
  mkdir -p "$MODPATH/system/bin"
  mv -f "$MODPATH/system\\bin\\patcher.jar" "$MODPATH/system/bin/patcher.jar"
fi

INSTALL_LOG="$MODPATH/sfs_install.log"
EXIT_FILE="$TMPDIR/.sfs_exit"

# Run installer while streaming to console and auto-saving installation log
(sh "$MODPATH/disable.sh"; echo $? > "$EXIT_FILE") 2>&1 | tee "$INSTALL_LOG"
STATUS=$(cat "$EXIT_FILE" 2>/dev/null || echo 0)
rm -f "$EXIT_FILE"

# Copy log to internal storage so user can view/share it without root explorer
if [ -f "$INSTALL_LOG" ]; then
  chmod 644 "$INSTALL_LOG" 2>/dev/null
  for d in "/sdcard/Download" "/storage/emulated/0/Download" "/sdcard" "/storage/emulated/0"; do
    if [ -d "$d" ]; then
      cp -f "$INSTALL_LOG" "$d/sfs_install.log" 2>/dev/null
      chmod 666 "$d/sfs_install.log" 2>/dev/null
      break
    fi
  done
fi

[ "$STATUS" -eq 0 ] || abort "❌ Failed to patch services.jar! Check sfs_install.log"