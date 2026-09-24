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

# Run installer
sh "$MODPATH/disable.sh" || abort "❌ Failed to patch services.jar! Save and Check logs."