#!/system/bin/sh

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

INSTALL_LOG="$MODPATH/sfs_install.log"
EXIT_FILE="$TMPDIR/.sfs_exit"

(sh "$MODPATH/disable.sh"; echo $? > "$EXIT_FILE") 2>&1 | tee "$INSTALL_LOG"
STATUS=$(cat "$EXIT_FILE" 2>/dev/null || echo 0)
rm -f "$EXIT_FILE"

if [ -f "$INSTALL_LOG" ]; then
  chmod 644 "$INSTALL_LOG" 2>/dev/null
fi

chmod 755 "$MODPATH/post-fs-data.sh" 2>/dev/null
chmod 755 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/action.sh" 2>/dev/null

[ "$STATUS" -eq 0 ] || abort "❌ Failed to patch services.jar! Check sfs_install.log"