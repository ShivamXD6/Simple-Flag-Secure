# Variables & Functions
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

# Check for volume key
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

# Handle Options based on key pressed
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
  rm -f "$MODPATH/disable.sh"
  rm -rf "$BIN"
  rm -rf "$DB/TMP"
}

# Function to edit Smali Files
smali_kit() {
   local count=0 check file path method replace rim newline oldline dim dim_oldline remake al al_add bl bl_add staticname smaliname limit
   while [[ $# -gt 0 ]]; do
      case $1 in
         -f|-file) file=$2; shift 2;;
         -d|-dir) path=$2; shift 2;;
         -m|-method) method=$2; shift 2;;
         -r|-replace) replace=$2; shift 2;;
         -rim|-replace-in-method) rim=1; oldline=$2; newline=$3; shift 3;;
         -dim|-delete-in-method) dim=1; dim_oldline=$2; shift 2;;
         -re|-remake) remake=$2; shift 2;;
         -al|-after-line) al=$2; al_add=$3; shift 3;;
         -bl|-before-line) bl=$2; bl_add=$3; shift 3;;
         -c|-check) check=1; shift;;
         -n|-name) smaliname=$2; shift 2;;
         -sn|-static-name) staticname=$2; shift 2;;
         -l|-limit) limit=$2; shift 2;;
      esac
   done
   local targets
   if [[ -n $path && -n $method ]]; then
      mapfile -t targets < <(grep -rl --include="*.smali" "$method" "$path")
   elif [[ -n $file && -n $method ]]; then
      targets=("$file")
   else
      echo "smali_kit: Invalid line"
      return 1
   fi
   for dir in "${targets[@]}"; do
      local base=${dir##*/}
      [[ -n $staticname && $base != "$staticname" ]] && continue
      [[ -n $smaliname && $base != *"$smaliname"* ]] && continue
      grep -nw "$method" "$dir" | while IFS=: read -r num liner; do
         [[ $liner != *".method"* ]] && continue
         local line old try load stock edit
         line=$(sed -e 's/[]\/$*.^[]/\\&/g' <<<"$liner")
         if [[ -z $replace && -z $rim && -z $remake && -z $al && -z $bl && -z $dim ]]; then
            echo "path=$dir"
            sed -n "/$line/,/\.end method/p" "$dir"
            continue
         fi
         load=$(<"$dir")
         old=$(sed -n "/$line/,/\.end method/p" "$dir")
         try=$old
         [[ -n $replace ]] && try=$replace
         [[ -n $rim && -n $oldline && -n $newline ]] && try=$(sed "s|$oldline|$newline|" <<<"$old")
         [[ -n $dim && -n $dim_oldline ]] && try=$(sed "/$dim_oldline/d" <<<"$old")
         [[ -n $remake ]] && try="$liner"$'\n'"$remake"$'\n'".end method"
         [[ -n $bl && -n $bl_add ]] && try=$(sed "/$bl/i $bl_add" <<<"$old")
         [[ -n $al && -n $al_add ]] && try=$(sed "/$al/a $al_add" <<<"$old")
         printf '%s' "${load/$old/$try}" > "$dir"
         ((count++))
         if [[ -n $check ]]; then
            sfs "\n🧩 Patched: $liner\n🛠️ With: $remake📁 In: $dir\n"
            [ ! -f "${dir%%/com/android/*}/patched" ] && touch "${dir%%/com/android/*}/patched"
         fi
         [[ -n $limit && $limit -eq $count ]] && break 2
      done
   done
}

# Function to Run apktool.jar using dalvikvm
apktool() {
  dalvikvm -Xmx512m -cp "$BIN/apktool.jar" brut.apktool.Main -p "$TMPDIR" "$@"
}

# Patch jar Files
patch_jar() {
  local jar_path="$1"
  declare -n patch_map="$2"  
  declare -A services_patch=(
   ["isSecureLocked"]="$false"
   ["isSecureWindow"]="$false"
   ["notAllowCaptureDisplay"]="$false"
   ["hasSecureWindowOnScreen"]="$false"
   ["hasSecure"]="$false"
   ["canBeScreenshotTarget"]="$true"
   ["notifyScreenshotListeners"]="$list"
   ["isAllowAudioPlaybackCapture"]="$true"
   ["isScreenCaptureAllowed"]="$true"
   ["getScreenCaptureDisabled"]="$false"
   ["containsSecureLayers"]="$false"
   ["dumpWindowsForScreenShot"]="$true"
  )
  declare -A oneui_patch=(
   ["isSecureLocked"]="$false"
   ["canBeScreenshotTarget"]="$true"
  )
  declare -A hyperos_patch=(
   ["notAllowCaptureDisplay"]="$false"
   ["containsSecureLayers"]="$false"
  )
  declare -A oplus_patch=(
   ["hasSecure"]="$false"
   ["isSecureWindow"]="$false"
   ["dumpWindowsForScreenShot"]="$true"
  )
  local jar_name="${jar_path##*/}"
  local jar_base="${jar_name%.*}"  
  cp -af "$jar_path" "$DB/$jar_name"
  if ! unzip -l "$jar_path" | grep -q classes.dex; then
    sfs "❌ You need a deodexed $jar_name" "hx"
    return 1
  fi
  sfs " 👾 Decompiling $jar_name" "h"
  apktool d -f "$jar_path" -o "$TMPDIR/services" || return 1
  sfs " 🧩 Patching Smali Files" "h"
  local method prefix
  for method in "${!patch_map[@]}"; do
    for prefix in "" "public "; do
      smali_kit -c -m ".method ${prefix}${method}" -re "${patch_map[$method]}" -d "$TMPDIR/services" &
    done
    while [ "$(jobs -rp | wc -l)" -gt 7 ]; do sleep 0.2; done
  done; wait
  find "$TMPDIR/services" -mindepth 1 -maxdepth 1 -type d ! -name "unknown" ! -name "original" -exec sh -c '[ ! -f "$1/patched" ] && rm -rf "$1"' _ {} \;
  rm -f "$TMPDIR/services"/*/patched
  sfs " 👾 Recompiling $jar_name" "h"
  apktool b -f "$TMPDIR/services" -o "$TMPDIR/services.jar" || return 1
  sfs "🖇️ Replacing only the modified dex file" "h"
  rm -rf "$TMPDIR/ORG" "$TMPDIR/MOD"
  mkdir -p "$TMPDIR/ORG" "$TMPDIR/MOD" "$DB/MOD"
  unzip -qo "$jar_path" -d "$TMPDIR/ORG"
  cp -af "$TMPDIR/services/build/apk"/*.dex "$TMPDIR/ORG"
  cd "$TMPDIR/ORG"
  "$BIN/zip" -qr "$MOD/$jar_name" .
  cp -af "$MOD/$jar_name" "$DB/MOD/$jar_name"
  rm -rf "$TMPDIR/services"
  return 0
}

# Run apktool.jar in different Sessions to avoid Segmentation fault
run() {
  local jar="$1"
  local patch="$2"
  export MODPATH BIN STOCK MOD DB TMPDIR ARCH true false list
  export -f sfs smali_kit patch_jar apktool
  "$BIN/bash" -c "patch_jar \"$jar\" \"$patch\"" || {
    sfs "💥 Dalvik crashed while patching $jar"
    return 1
  }
}

# Check for OEM services.jar and patch it
check_and_patch() {
  local jar_path="$1"
  local label="$2"
  local patch_map="$3"
  if [ -f "$jar_path" ]; then
    sfs "🔍 $label detected" "h"
    sfs "⏳ Patching may work better but takes time.\n⚡ Skipping is faster but might fail if screenshot blocking exists."
    sfs "🔊 Vol+ = Patch It\n🔉 Vol- = Skip It"; opt
    [ $? -eq 0 ] && run "$jar_path" "$patch_map"
  fi
}

# Module Info UI
sfs "👀 $(padh "name" "$MODPATH/module.prop")" "h#" 1
sfs "🌟 Made By $(padh "author" "$MODPATH/module.prop")"
sfs "⚡ Version - $(padh "version" "$MODPATH/module.prop")"
sfs "💻 Architecture - $ARCH"
sfs "📝 $(padh "description" "$MODPATH/module.prop")"
sfs "📝 Please Save Installation Logs" "h*"

# Clean flash or dirty flash
[ -f "$DB/MOD/services.jar" ] && {
sfs "🤔 Do you want to clean install or dirty install?" 1 "h"
sfs "🔊 Vol+ = Clean Install (Recompile again - slower)\n🔉 Vol- = Dirty Install (Reuse existing - faster)"; opt
if [ $? -eq 0 ]; then
  sfs "🧹 Performing Clean Flash"
  rm -rf "$DB" && mkdir -p "$DB"
else
  sfs "🧼 Performing Dirty Flash"
fi 
}

# Start Patching jars
run "$STOCK/services.jar" services_patch || exit 1
check_and_patch "/system/framework/semwifi-service.jar" "OneUI" "oneui_patch"
check_and_patch "/system_ext/framework/miui-services.jar" "MIUI / HyperOS" "hyperos_patch"
check_and_patch "/system/framework/oplus-services.jar" "Oplus (RealmeUI/ColorOS/OxygenOS)" "oplus_patch"

# Prompt to join the channel if liked :)
sfs "🔗 @BuildBytes is quietly building things worth exploring. Want to be there early?" "h#"
sfs "🔊 Vol+ = Yes, I’m in. early, curious, and ahead\n🔉 Vol- = No, I’ll scroll past and miss it\n"; opt
if [ $? -ne 1 ]; then
  am start -a android.intent.action.VIEW -d https://telegram.me/BuildBytes >/dev/null 2>&1
else
  sfs "🫥 You passed.\nNo noise, no regret, just a silent skip over something built with intent.\nI’ll stay here, quietly excellent, waiting for those who notice before it’s popular."
fi
clean
sfs "✨ All done! You can reboot now." 1 "h#"