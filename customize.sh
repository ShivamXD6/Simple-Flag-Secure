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

# Run Main Script
"$MODPATH"/system/bin/bash "$MODPATH/disable.sh"
