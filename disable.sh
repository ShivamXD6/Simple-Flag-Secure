# Run Functions and Get Variables
## Variables
MODPATH="${0%/*}"
BIN="$MODPATH/system/bin"
STOCK="/system/framework"
MOD="$MODPATH/system/framework"
DB="/data/#SFS"
TMPDIR="$DB"/TMP
mkdir -p "$TMPDIR"
disable='
    .locals 1

    const/4 v0, 0x0

    return v0
'

## Functions

# Print Function
sfs() {
      echo "$1"
      echo ""
}

# Cleanup Function
clean() {
  rm -rf "$MODPATH/disable.sh"
  rm -rf "$BIN/aapt"
  rm -rf "$BIN/apktool.jar"
  rm -rf "$BIN/zip"
  rm -rf "$BIN/bash"
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

# Set Permissions
set_perm() {
  chown "$1:$2" "$4"
  chmod "$3" "$4"
}

# Function to edit Smali Files
smali_kit() {
   #Smali Tool kit for Dynamic Installer by BlassGO
   local dir num line liner old new count=0 restore load try log
   local file path method replace limit rim newline oldline check stock edit smaliname remake
   local get al al_add bl bl_add staticname dim dim_oldline
   local restore flag 
   restore=()
   while [[ $# -gt 0 ]]; do
   flag="$1"
   case $flag in
       -f|-file)
       file="$2"
       shift 2
       ;;
       -d|-dir)
       path="$2"
       shift 2
       ;;
       -m|-method)
       method="$2"
       shift 2
       ;;
       -r|-replace)
       replace="$2"
       shift 2
       ;;
       -rim|-replace-in-method)
       rim=true
       oldline="$2"
       newline="$3"
       shift 3
       ;;
       -dim|-delete-in-method)
       dim=true
       dim_oldline="$2"
       shift 2
       ;;
       -re|-remake)
       remake="$2"
       shift 2
       ;;
       -al|-after-line)
       al="$2"
       al_add="$3"
       shift 3
       ;;
       -bl|-before-line)
       bl="$2"
       bl_add="$3"
       shift 3
       ;;
       -c|-check)
       check=true
       shift
       ;;
       -n|-name)
       smaliname="$2"
       shift 2
       ;;
       -sn|-static-name)
       staticname="$2"
       shift 2
       ;;
       -l|-limit)
       limit="$2"
       shift 2
       ;;
       *)   
       restore+=("$1")
       shift
       ;;
   esac
   done
   set -- "${restore[@]}"
   if [[ -z "$file" && -n "$path" && -n "$method" ]]; then
      grep -rnw "$path" -e "$method" | while read huh; do
         stock=
         edit=
         dir=$(echo "$huh" | cut -f1 -d:)
         num=$(echo "$huh" | cut -f2 -d:)
         liner=$(echo "$huh" | cut -f3 -d:)
         if [[ "$liner" == *".method"* ]]; then
            if [[ -n "$staticname" && "$(basename "$dir")" != "$staticname" ]]; then continue; fi
            if [[ -n "$smaliname" && "$(basename "$dir")" != *"$smaliname"* ]]; then continue; fi
            line=$(echo "$liner" | sed -e 's/[]\/$*.^[]/\\&/g')
            savestate stock "$dir"
            if [[ -z "$replace" && -z "$rim" && -z "$remake" && -z "$al" && -z "$bl" && -z "$dim" ]]; then
               echo "path="$dir""
               sed -n "/$line/,/\.end method/p" "$dir"
            fi
            if [ -n "$replace" ]; then
               load=$(cat "$dir")
               old=$(sed -n "/$line/,/\.end method/p" "$dir")
               echo "${load/$old/$replace}" > "$dir"
            fi
            if [[ -n "$rim" && -n "$oldline" && -n "$newline" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$dir")
               try=$(echo "${old/$oldline/$newline}")
               load=$(cat "$dir")
               echo "${load/$old/$try}" > "$dir"
            fi
            if [[ -n "$dim" && -n "$dim_oldline" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$dir")
               try=${old//$dim_oldline/}
               load=$(cat "$dir")
               echo "${load/$old/$try}" > "$dir"
            fi
            if [ -n "$remake" ]; then
               old=$(sed -n "/$line/,/\.end method/p" "$dir")
               echo "${liner}" > "$DB/re.tmp"
               echo "$remake" >> "$DB/re.tmp"
               echo "${n}.end method" >> "$DB/re.tmp"
               try=$(cat "$DB/re.tmp")
               rm -f "$DB/re.tmp" 2>/dev/null
               load=$(cat "$dir")
               echo "${load/$old/$try}" > "$dir"
            fi
            if [[ -n "$bl" && -n "$bl_add" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$dir") 
               echo "$bl_add" > "$DB/bl.tmp"
               get=$(sed '$!s/$/\\/' $DB/bl.tmp)
               rm -f $DB/bl.tmp
               try=$(echo "$old" | sed "/$bl/i $get")
               load=$(cat "$dir")
               echo "${load/$old/$try}" > "$dir"
            fi
            if [[ -n "$al" && -n "$al_add" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$dir") 
               echo "$al_add" > "$DB/al.tmp"
               get=$(sed '$!s/$/\\/' $DB/al.tmp)
               rm -f $DB/al.tmp
               try=$(echo "$old" | sed -e "/$al/a $get")
               load=$(cat "$dir")
               echo "${load/$old/$try}" > "$dir"
            fi
            savestate edit "$dir"
            count=$(( $count + 1 ))
            if [ -n "$check" ]; then if [[ "$edit" != "$stock" ]]; then echo "Edited: "$dir""; else echo "Nothing: "$dir""; fi; fi
           setprop SMALI "$dir"
            if [[ -n "$limit" && "$limit" == "$count" ]]; then break; fi
         fi
      done
   elif [[ -n "$file" && -z "$path" && -n "$method" ]]; then
      grep -nw "$file" -e "$method" | while read huh; do
         stock=
         edit=
         num=$(echo "$huh" | cut -f1 -d:)
         liner=$(echo "$huh" | cut -f2 -d:)
         if [[ "$liner" == *".method"* ]]; then
         if [[ -n "$staticname" && "$(basename "$file")" != "$staticname" ]]; then continue; fi
         if [[ -n "$smaliname" && "$(basename "$file")" != *"$smaliname"* ]]; then continue; fi
            line=$(echo "$liner" | sed -e 's/[]\/$*.^[]/\\&/g')
            savestate stock "$file"
            if [[ -z "$replace" && -z "$rim" && -z "$remake" && -z "$al" && -z "$bl" ]]; then
               echo "path="$dir""
               sed -n "/$line/,/\.end method/p" "$file"
            fi
            if [ -n "$replace" ]; then
               load=$(cat "$file")
               old=$(sed -n "/$line/,/\.end method/p" "$file")
               echo "${load/$old/$replace}" > "$file"
            fi
            if [[ -n "$rim" && -n "$oldline" && -n "$newline" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$file")
               try=$(echo "${old/$oldline/$newline}")
               load=$(cat "$file")
               echo "${load/$old/$try}" > "$file"
            fi
            if [[ -n "$dim" && -n "$dim_oldline" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$file")
               try=${old//$dim_oldline/}
               load=$(cat "$file")
               echo "${load/$old/$try}" > "$file"
            fi
            if [ -n "$remake" ]; then
               old=$(sed -n "/$line/,/\.end method/p" "$file")
               echo "${liner}" > "$DB/re.tmp"
               echo "$remake" >> "$DB/re.tmp"
               echo "${n}.end method" >> "$DB/re.tmp"
               try=$(cat "$DB/re.tmp")
               rm -f "$DB/re.tmp" 2>/dev/null
               load=$(cat "$file")
               echo "${load/$old/$try}" > "$file"
            fi
            if [[ -n "$bl" && -n "$bl_add" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$file") 
               echo "$bl_add" > "$DB/bl.tmp"
               get=$(sed '$!s/$/\\/' $DB/bl.tmp)
               rm -f $DB/bl.tmp
               try=$(echo "$old" | sed "/$bl/i $get")
               load=$(cat "$file")
               echo "${load/$old/$try}" > "$file"
            fi
            if [[ -n "$al" && -n "$al_add" ]]; then
               old=$(sed -n "/$line/,/\.end method/p" "$file") 
               echo "$al_add" > "$DB/al.tmp"
               get=$(sed '$!s/$/\\/' $DB/al.tmp)
               rm -f $DB/al.tmp
               try=$(echo "$old" | sed -e "/$al/a $get")
               load=$(cat "$file")
               echo "${load/$old/$try}" > "$file"
            fi
            savestate edit "$file"
            count=$(( $count + 1 ))
            if [ -n "$check" ]; then if [[ "$edit" != "$stock" ]]; then echo "Edited: "$file""; else echo "Nothing: "$file""; fi; fi
            if [[ -n "$limit" && "$limit" == "$count" ]]; then break; fi
         fi
      done
   else
      echo " smali_kit: Invalid line " && return 
   fi
}

# Function to run JAR files using dalvikvm
run_jar() {
    local dalvikvm file main 
    #Inspired in the osm0sis method
    if dalvikvm -showversion >/dev/null; then
       dalvikvm=dalvikvm
    elif /system/bin/dalvikvm -showversion >/dev/null; then 
       dalvikvm=/system/bin/dalvikvm
    else
       echo "CANT LOAD DALVIKVM " && return
    fi
    file="$1"
    unzip -o "$file" "META-INF/MANIFEST.MF" -p > "/data/main.tmp"
    main=$(cat /data/main.tmp | grep -m1 "^Main-Class:" | cut -f2 -d: | tr -d " " | dos2unix)
    rm -f /data/main.tmp
    if [ -z "$main" ]; then
       echo "Cant get main: $file " && return
    fi
    shift 1
    $dalvikvm -Djava.io.tmpdir=. -Xnodex2oat -Xnoimage-dex2oat -cp "$file" $main "$@" 2>/dev/null \ || $dalvikvm -Djava.io.tmpdir=. -Xnoimage-dex2oat -cp "$file" $main "$@"
}

# Function to Run apktool.jar using run_jar
apktool() {
   cp -f /system/framework/framework-res.apk "$TMPDIR"/1.apk
   run_jar "$BIN"/apktool.jar --aapt "$BIN"/aapt -p "$TMPDIR" "$@"
}

# Check for Deodex Services.jar
if ! unzip -l "$STOCK"/services.jar | grep classes.dex >/dev/null; then
   sfs " ❎ - You need a deodexed services.jar"
   exit 1
fi

# Installation Begin
echo ""
sfs " ⚡ Simple Flag Secure ⚡"
sfs " ✨ For Magisk, KSU and APatch"
sfs " ✅ By @ShastikXD"

# Check if Module Already used once
if [ -f "$DB/services.jar" ]; then
sfs " 💾 - Found A Backup, Using it for Faster Installation"
mkdir -p "$MOD"
cp -af "$DB/services.jar" "$MOD/services.jar"
sfs " ✨ - Installation Done Reboot Now"
else 

# Make Framework Dir
mkdir -p "$MOD"
sfs " ⚡ - This will take 2-3 mins for the first time flashing"
sfs " ⚡ - Flashing again this module on same rom will be faster. "

# Decompiling with apktool
sfs " 👾 - Decompiling services.jar"
apktool d "$STOCK"/services.jar -o "$TMPDIR/services"

# Apply smali patches
echo ""
sfs " 🧩 - Patching Smali Files"
smali_kit -c -m "isSecureLocked" -re "$disable" -d "$TMPDIR/services"
smali_kit -c -m "preventTakingScreenshotToTargetWindow" -re "$disable" -d "$TMPDIR/services"

# Recompiling with apktool
echo ""
sfs " 👾 - Recompiling services.jar"
apktool b "$TMPDIR/services" -o "$MOD/services.jar"

# Check for Smali Dir which is edited
echo ""
sfs " 🖇️ - Replacing Modified Dex File Only"
Smali="$(getprop SMALI)"

# Loop less then 20 times to get Smali Dir Name
cnt=1
while [[ "$cnt" -lt 20 && "$(basename "$Smali")" != "smali" && "$(basename "$Smali")" != "smali_classes2" && "$(basename "$Smali")" != "smali_classes3" && "$(basename "$Smali")" != "smali_classes4" && "$(basename "$Smali")" != "smali_classes5" ]]; do
    Smali=$(dirname "$Smali")   
    cnt=$((cnt + 1))
done

# Check if Smali dir exist
if [ "$cnt" -lt 20 ]; then
Smali=$(basename "$Smali")

# If Smali Dir exists, change classes.dex according to Smali dir 
if [[ "$(basename "$Smali")" == "smali" ]]; then
    Class="classes.dex"
else
    suffix=$(echo "$Smali" | sed 's/smali_classes//')
    Class="classes${suffix}.dex"
fi

# Change Only Modified classes.dex file, keep rest untouched
mkdir -p "$TMPDIR/ORG"
mkdir -p "$TMPDIR/MOD"
unzip -o "$STOCK"/services.jar -d "$TMPDIR/ORG" >> /dev/null;
unzip -o "$MOD/services.jar" -d "$TMPDIR/MOD" >> /dev/null;
cp -af "$TMPDIR/MOD/$Class" "$TMPDIR/ORG/$Class"
cd "$TMPDIR/ORG"

# Recompress services.jar to avoid breaking anything
$BIN/zip -r "$MOD"/services.jar . >> /dev/null;
sfs " 🔗 - Compressing Services JAR"
cp -af "$MOD/services.jar" "$DB/services.jar"
fi
clean
sfs " ✨ - Installation Done Reboot Now"
fi
