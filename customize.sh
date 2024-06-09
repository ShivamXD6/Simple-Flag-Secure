#!/system/bin/sh

# Abort in Recovery 
if ! $BOOTMODE; then
  ui_print " ! Only uninstall is supported in recovery"
  ui_print " - Uninstalling Simple Flag Secure!"
  touch $MODPATH/remove
  sh $MODPATH/uninstall.sh
  recovery_cleanup
  rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
  exit 0
fi

# Run Disable Script
"$MODPATH"/system/bin/bash "$MODPATH/disable.sh"