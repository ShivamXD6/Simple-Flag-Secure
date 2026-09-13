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
  recovery_cleanup
  rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
  exit 0
fi

# Normalize backslash paths if extracted by Windows zip tools
if [ -f "$MODPATH/system\\bin\\patcher.jar" ]; then
  mkdir -p "$MODPATH/system/bin"
  mv -f "$MODPATH/system\\bin\\patcher.jar" "$MODPATH/system/bin/patcher.jar"
fi

# Run Main Script
sh "$MODPATH/disable.sh" || abort "❌ Failed to patch services.jar! Save and Check logs."
am start -a android.intent.action.VIEW -d https://telegram.me/BuildBytes >/dev/null 2>&1