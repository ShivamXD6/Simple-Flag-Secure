## Variables
MODPATH="${0%/*}"
BIN="$MODPATH/system/bin"
STOCK="/system/framework"
MOD="$MODPATH/system/framework"
DB="/data/#SFS"
TMPDIR="$DB/TMP"
ARCH=$(getprop ro.product.cpu.abi)

# Patch Bodies for Methods
true='
    .locals 1
    const/4 v0, 0x1
    return v0
'

false='
    .locals 1
    const/4 v0, 0x0
    return v0
'

list='
    .locals 1
    new-instance v0, Ljava/util/ArrayList;
    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V
    return-object v0
'

# Only 64-Bit Supported
[[ "$ARCH" =~ arm64-v8a ]] || {
  DEKH "🧨 This module requires a 64-bit environment. Exiting..."
  exit 1
}

## Functions

# Print Function
sfs() {
  orgsandesh="$1"; samay="${2:-0.2}"; prakar="${3}"
  [[ "$2" == h* ]] && prakar="${2}" && samay="${3:-0.2}"
  echo "$orgsandesh" | grep -q '[^ -~]' && sandesh=" $orgsandesh" || sandesh=" $orgsandesh "
  rekha=$(printf "%s\n" "$sandesh" | awk '{ print length }' | sort -nr | head -n1)
  [ "$rekha" -gt 50 ] && rekha=50
  akshar=(= - ~ '*' + '<' '>')
  [[ "$prakar" == h* ]] && {
    shabd="${prakar#h}"; [ -z "$shabd" ] && shabd="${akshar[RANDOM % ${#akshar[@]}]}"
    echo; printf '%*s\n' "$rekha" '' | tr ' ' "$shabd"
    echo -e "$sandesh"
    printf '%*s\n' "$rekha" '' | tr ' ' "$shabd"
  } || echo -e "$orgsandesh"
  sleep "$samay"
}

## Check for volume key
checkkey() {
while true; do
  key_code=$(getevent -qlc 1 | grep "KEY_" | awk '{print $3}')
  if [ -n "$key_code" ]; then
    echo "$key_code"
    sleep 1
    break
  fi
  sleep 0.1
done
}

## Handle Options based on key pressed
opt() {
while true; do
  key=$(checkkey)
  case $key in
    KEY_VOLUMEUP)
      return 0
      ;;
    KEY_VOLUMEDOWN)
      return 1
      ;;
    KEY_POWER)
      return 2
      ;;
    *)
      sfs "❌ Invalid Key! Try Again. Key pressed: $key"
      ;;
  esac
done
}

# Read Files
padh() {
  value=$(grep -m 1 "^$1=" "$2" | sed 's/^.*=//')
  echo "${value//[[:space:]]/ }"
}

# Cleanup Function
clean() {
  rm -rf "$MODPATH/disable.sh"
  rm -rf "$BIN"
  rm -rf "$DB"/TMP
}

# Set Default value
setdefault() {
  read -r -d '' "$1" <<< "$2"
}

# Save State
savestate() {
  setdefault "$1" "$(md5sum "$2")"
}

# Function to edit Smali Files
smali_kit() {
   # Smali Toolkit for Dynamic Installer by BlassGO (Optimized by ShastikXD)
   local count=0 restore=() check file path method replace rim newline oldline dim dim_oldline remake al al_add bl bl_add staticname smaliname limit
   while [[ $# -gt 0 ]]; do
      case $1 in
         -f|-file) file="$2"; shift 2;;
         -d|-dir) path="$2"; shift 2;;
         -m|-method) method="$2"; shift 2;;
         -r|-replace) replace="$2"; shift 2;;
         -rim|-replace-in-method) rim=1; oldline="$2"; newline="$3"; shift 3;;
         -dim|-delete-in-method) dim=1; dim_oldline="$2"; shift 2;;
         -re|-remake) remake="$2"; shift 2;;
         -al|-after-line) al="$2"; al_add="$3"; shift 3;;
         -bl|-before-line) bl="$2"; bl_add="$3"; shift 3;;
         -c|-check) check=1; shift;;
         -n|-name) smaliname="$2"; shift 2;;
         -sn|-static-name) staticname="$2"; shift 2;;
         -l|-limit) limit="$2"; shift 2;;
         *) restore+=("$1"); shift;;
      esac
   done
   set -- "${restore[@]}"
   local targets
   if [[ -n "$path" && -n "$method" ]]; then
      targets=$(grep -rl --include="*.smali" "$method" "$path")
   elif [[ -n "$file" && -n "$method" ]]; then
      targets="$file"
   else
      echo " smali_kit: Invalid line " && return
   fi
   for dir in $targets; do
      local base=$(basename "$dir")
      [[ -n "$staticname" && "$base" != "$staticname" ]] && continue
      [[ -n "$smaliname" && "$base" != *"$smaliname"* ]] && continue
      while IFS= read -r huh; do
         local line liner old try load stock edit get
         local num=$(echo "$huh" | cut -f1 -d:)
         liner=$(echo "$huh" | cut -f2- -d:)

         [[ "$liner" != *".method"* ]] && continue
         line=$(echo "$liner" | sed -e 's/[]\/$*.^[]/\\&/g')
         savestate stock "$dir"
         [[ -z "$replace" && -z "$rim" && -z "$remake" && -z "$al" && -z "$bl" && -z "$dim" ]] && {
            echo "path=$dir"
            sed -n "/$line/,/\.end method/p" "$dir"
            continue
         }
         load=$(cat "$dir")
         old=$(sed -n "/$line/,/\.end method/p" "$dir")
         try="$old"
         [[ -n "$replace" ]] && try="$replace"
         [[ -n "$rim" && -n "$oldline" && -n "$newline" ]] && try=$(echo "$old" | sed "s|$oldline|$newline|")
         [[ -n "$dim" && -n "$dim_oldline" ]] && try=$(echo "$old" | sed "/$dim_oldline/d")
         if [[ -n "$remake" ]]; then
            echo "$liner" > "$DB/re.tmp"
            echo "$remake" >> "$DB/re.tmp"
            echo ".end method" >> "$DB/re.tmp"
            try=$(cat "$DB/re.tmp")
            rm -f "$DB/re.tmp"
         fi
         if [[ -n "$bl" && -n "$bl_add" ]]; then
            echo "$bl_add" > "$DB/bl.tmp"
            get=$(sed '$!s/$/\\/' "$DB/bl.tmp")
            rm -f "$DB/bl.tmp"
            try=$(echo "$old" | sed "/$bl/i $get")
         fi
         if [[ -n "$al" && -n "$al_add" ]]; then
            echo "$al_add" > "$DB/al.tmp"
            get=$(sed '$!s/$/\\/' "$DB/al.tmp")
            rm -f "$DB/al.tmp"
            try=$(echo "$old" | sed "/$al/a $get")
         fi
         echo "${load/$old/$try}" > "$dir"
         savestate edit "$dir"
         ((count++))
         [[ -n "$check" ]] && {
            [[ "$edit" != "$stock" ]] && sfs "🧩 - Patched: $remake\n📁 - In: $dir" && echo ""
         }
         setprop SMALI "$dir"
         [[ -n "$limit" && "$limit" -eq "$count" ]] && break
      done <<< "$(grep -nw "$method" "$dir")"
   done
}

# Function to run JAR files
run_jar() {
    local file main
    if command -v dalvikvm >/dev/null 2>&1; then
        VM=dalvikvm
        VM_TYPE=dalvik
    elif [ -x /system/bin/dalvikvm ]; then
        VM=/system/bin/dalvikvm
        VM_TYPE=dalvik
    elif command -v app_process >/dev/null 2>&1; then
        VM=app_process
        VM_TYPE=app_process
    elif [ -x /system/bin/app_process ]; then
        VM=/system/bin/app_process
        VM_TYPE=app_process
    else
        sfs "❌ Cannot find dalvikvm or app_process"
        return 1
    fi
    file="$1"
    shift
    unzip -p "$file" META-INF/MANIFEST.MF | grep -m1 "^Main-Class:" | cut -d: -f2 | tr -d ' \r' > /data/main.tmp
    main=$(cat /data/main.tmp)
    rm -f /data/main.tmp
    if [ -z "$main" ]; then
        sfs "❌ Could not find Main-Class in $file"
        return 1
    fi
    case "$VM_TYPE" in
        dalvik)
            "$VM" -Djava.io.tmpdir=. -Xnodex2oat -Xnoimage-dex2oat -cp "$file" "$main" "$@" 2>/dev/null \
            || "$VM" -Djava.io.tmpdir=. -Xnoimage-dex2oat -cp "$file" "$main" "$@"
            ;;
        app_process)
            "$VM" /system/bin "$main" "$@"
            ;;
    esac
}

# Module Info UI
sfs "👀 $(padh "name" "$MODPATH/module.prop")" "h#" 1
sfs "🌟 Made By $(padh "author" "$MODPATH/module.prop")"
sfs "⚡ Version - $(padh "version" "$MODPATH/module.prop")"
sfs "💻 Architecture - $ARCH"
sfs "📝 $(padh "description" "$MODPATH/module.prop")"
sfs "📝 Please Save Installation Logs" "h*"

# Clean flash or dirty flash
sfs "🤔 Do you want to clean install or dirty install?" 1 "h"
sfs "🔊 Vol+ = Clean Install\n🔉 Vol- = Dirty Install"
opt
if [ $? -eq 0 ]; then
  sfs "🧹 Performing Clean Flash"
  rm -rf "$DB"
else
  sfs "🧼 Performing Dirty Flash"
fi 

# Check for Backup Dir
if [ ! -d "$DB/MOD" ] || [ -d "$DB/TMP" ]; then
  rm -rf "$DB" # Delete OLD Backup of Vwhere 2
  mkdir -p "$DB/MOD"
  mkdir -p "$TMPDIR"
fi

# Function to Run apktool.jar using run_jar
apktool() {
  run_jar "$BIN/apktool.jar" -p "$TMPDIR" "$@"
}

# Function to find BusyBox binary
BBOX() {
  [ -n "$BUSYBOX" ] && return 0
  local path
  for path in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -f "$path" ]; then
      export BB="$path"
      return 0
    fi
  done
  return 1
}
BBOX

# Check for Deodex services.jar
if ! unzip -l "$STOCK"/services.jar | grep classes.dex >/dev/null; then
  sfs " ❎ - You need a deodexed services.jar"
  exit 1
fi

# Sync and Drop Caches
sync
echo 3 > /proc/sys/vm/drop_caches

# Perform fstrim to speed up heavy I/O (helps apktool decompile/recompile faster)
sfs "🚀 Trimming blocks for Better I/O Speed" 1 "h"
for part in /system /data /cache; do
  "$BB" fstrim -v "$part" 2>/dev/null || true
done
echo ""

# Check if Module Already used once
if [ -f "$DB/MOD/services.jar" ]; then
sfs "💾 Found a backup! restoring it" 1 "h"
cp -af "$DB/MOD/services.jar" "$MOD/services.jar"
rm -rf "$DB/TMP"
sfs "✨ All done! You can reboot now." 1 "h"
else 
sfs "⚡ First-time setup may take 2–3 minutes.\n⚡ Reflashing on the same ROM will be quicker." 1
cp -af "$STOCK/services.jar" "$DB/services.jar"

# Decompiling with apktool
sfs " 👾 Decompiling services.jar" 1 "h"
apktool d -f "$STOCK"/services.jar -o "$TMPDIR/services"

# Apply smali patches
sfs " 🧩 Patching Smali Files" 1 "h"

# Method Replacement Map
declare -A method_map=(
  ["isSecureLocked"]="$false"
  ["preventTakingScreenshotToTargetWindow"]="$false"
  ["notAllowCaptureDisplay"]="$false"
  ["hasSecureWindowOnScreen"]="$false"
  ["hasSecure"]="$false"
  ["canBeScreenshotTarget"]="$true"
  ["notifyScreenshotListeners"]="$list"
)

# Apply patches for each method
for method in "${!method_map[@]}"; do
  for prefix in "" "public "; do
    smali_kit -c -m ".method ${prefix}${method}" -re "${method_map[$method]}" -d "$TMPDIR/services"
  done
done

# Recompiling with apktool
sfs " 👾 Recompiling services.jar" 1 "h"
apktool b "$TMPDIR/services" -o "$MOD/services.jar" 

# Replace only the modified dex in services.jar
sfs "🖇️ Replacing only the modified dex file" 1 "h"
Smali="$(getprop SMALI)"
cnt=1
while [[ "$cnt" -lt 20 && ! "$(basename "$Smali")" =~ ^smali(_classes[2-5]?)?$ ]]; do
    Smali=$(dirname "$Smali")
    cnt=$((cnt + 1))
done

if [ "$cnt" -lt 20 ]; then
    SmaliBase=$(basename "$Smali")
    if [[ "$SmaliBase" == "smali" ]]; then
        Class="classes.dex"
    else
        suffix="${SmaliBase#smali_classes}"
        Class="classes${suffix}.dex"
    fi
    mkdir -p "$TMPDIR/ORG" "$TMPDIR/MOD"
    unzip -qo "$STOCK/services.jar" -d "$TMPDIR/ORG"
    unzip -qo "$MOD/services.jar" -d "$TMPDIR/MOD"
    cp -af "$TMPDIR/MOD/$Class" "$TMPDIR/ORG/$Class"
    cd "$TMPDIR/ORG" || exit 1
    "$BIN/zip" -qr "$MOD/services.jar" .
    cp -af "$MOD/services.jar" "$DB/MOD/services.jar"
fi
clean
sfs "✨ All done! You can reboot now." 1 "h"
fi
