#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(PROJECT_ROOT, "xposed_module", "res")
BASE_EMOJI_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "apple_1f440.png")

base_emoji = Image.open(BASE_EMOJI_PATH).convert("RGBA")

# Colors
os.makedirs(os.path.join(RES_DIR, "values"), exist_ok=True)
colors_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#16181D</color>
</resources>
"""
with open(os.path.join(RES_DIR, "values", "colors.xml"), "w", encoding="utf-8") as f:
    f.write(colors_xml)

# Adaptive icon XMLs
anydpi_dir = os.path.join(RES_DIR, "mipmap-anydpi-v26")
os.makedirs(anydpi_dir, exist_ok=True)
adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""
with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(adaptive_xml)
with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
    f.write(adaptive_xml)

# Densities for standard launcher icons
densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192
}

for folder, size in densities.items():
    d = os.path.join(RES_DIR, folder)
    os.makedirs(d, exist_ok=True)
    
    # 1. Squircle / rounded icon
    img_sq = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_sq = ImageDraw.Draw(img_sq)
    corner_r = int(size * 0.22)
    border_w = max(1, int(size * 0.015))
    draw_sq.rounded_rectangle([1, 1, size - 2, size - 2], radius=corner_r, fill=(22, 24, 29, 255), outline=(45, 49, 58, 255), width=border_w)
    
    e_size = int(size * 0.65)
    e_resized = base_emoji.resize((e_size, e_size), Image.Resampling.LANCZOS)
    x = (size - e_size) // 2
    y = (size - e_size) // 2
    img_sq.alpha_composite(e_resized, (x, y))
    img_sq.save(os.path.join(d, "ic_launcher.png"))
    
    # 2. Round icon
    img_rd = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_rd = ImageDraw.Draw(img_rd)
    draw_rd.ellipse([1, 1, size - 2, size - 2], fill=(22, 24, 29, 255), outline=(45, 49, 58, 255), width=border_w)
    img_rd.alpha_composite(e_resized, (x, y))
    img_rd.save(os.path.join(d, "ic_launcher_round.png"))

# Foreground for adaptive icon
fg_densities = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432
}

for folder, size in fg_densities.items():
    d = os.path.join(RES_DIR, folder)
    os.makedirs(d, exist_ok=True)
    fg_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Adaptive safe zone is inner 66% (72/108)
    e_size = int(size * 0.48)
    e_resized = base_emoji.resize((e_size, e_size), Image.Resampling.LANCZOS)
    x = (size - e_size) // 2
    y = (size - e_size) // 2
    fg_img.alpha_composite(e_resized, (x, y))
    fg_img.save(os.path.join(d, "ic_launcher_foreground.png"))

print("All icon assets generated successfully!")
