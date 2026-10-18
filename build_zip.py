#!/usr/bin/env python3
import os
import zipfile

OUTPUT_ZIP = "Simple_Flag_Secure_v10.0.zip"

FILES_TO_ADD = [
    ("META-INF/com/google/android/update-binary", "META-INF/com/google/android/update-binary"),
    ("META-INF/com/google/android/updater-script", "META-INF/com/google/android/updater-script"),
    ("action.sh", "action.sh"),
    ("customize.sh", "customize.sh"),
    ("disable.sh", "disable.sh"),
    ("module.prop", "module.prop"),
    ("post-fs-data.sh", "post-fs-data.sh"),
    ("service.sh", "service.sh"),
    ("system/bin/sfs.jar", "system/bin/sfs.jar"),
]

if os.path.exists(OUTPUT_ZIP):
    os.remove(OUTPUT_ZIP)

with zipfile.ZipFile(OUTPUT_ZIP, "w", zipfile.ZIP_DEFLATED) as zf:
    for src, arc in FILES_TO_ADD:
        arc_posix = arc.replace("\\", "/")
        with open(src, "rb") as f:
            content = f.read()
        if src.endswith(".sh") or src.endswith(".prop") or "META-INF" in src:
            content = content.replace(b"\r\n", b"\n")
        zf.writestr(arc_posix, content)
        print(f"  added: {arc_posix}")

size_mb = os.path.getsize(OUTPUT_ZIP) / (1024 * 1024)
print(f"\nBuilt {OUTPUT_ZIP} ({size_mb:.2f} MB) successfully with POSIX paths!")
