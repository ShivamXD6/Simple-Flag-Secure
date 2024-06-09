#!/system/bin/sh

SERVICES_JAR="/system/framework/services.jar"

delete_dalvik_cache() {
   rm -f "/data/dalvik-cache/arm/system@framework@services.jar@classes.dex"
   rm -f "/data/dalvik-cache/arm/system@framework@services.jar@classes.vdex"    
   rm -f "/data/dalvik-cache/arm64/system@framework@services.jar@classes.dex"   
   rm -f "/data/dalvik-cache/arm64/system@framework@services.jar@classes.vdex"
        
}

create_dalvik_cache() {      
    /system/bin/dexopt --opt=all --generate-cache --dex2oat_opt=quicken --apk $SERVICES_JAR  
}

delete_dalvik_cache

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

create_dalvik_cache

exit 0