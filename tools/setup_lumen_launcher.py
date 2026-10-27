#!/usr/bin/env python3
import os
import shutil
from PIL import Image, ImageDraw

REPO_ROOT = "/Users/dibble/Documents/GitHub/Lumen-OS"
APP_DIR = os.path.join(REPO_ROOT, "Apps", "LumenLauncher")
BIN_DIR = os.path.join(APP_DIR, "bin")
LIB_DIR = os.path.join(APP_DIR, "libs")

os.makedirs(BIN_DIR, exist_ok=True)
os.makedirs(LIB_DIR, exist_ok=True)

# Make launch.sh executable
launch_sh = os.path.join(APP_DIR, "launch.sh")
if os.path.isfile(launch_sh):
    os.chmod(launch_sh, 0o755)

# 1. Bundle / Link Love2D runtime
love_src = os.path.join(REPO_ROOT, "Apps", "PortMaster", "PortMaster", "runtimes", "love_11.5", "love.aarch64")
love_dst = os.path.join(BIN_DIR, "love.aarch64")
if os.path.isfile(love_src):
    shutil.copy2(love_src, love_dst)
    os.chmod(love_dst, 0o755)
    print(f"Bundled {love_dst}")

# Copy PortMaster runtime libraries if available
for lib_name in ["libfontconfig.so.1", "liblove-11.5.so", "libluajit-5.1.so.2", "libmodplug.so.1", "libogg.so.0", "libtheoradec.so.1"]:
    src_lib = os.path.join(REPO_ROOT, "System", "lib", lib_name)
    dst_lib = os.path.join(LIB_DIR, lib_name)
    if os.path.isfile(src_lib) and not os.path.exists(dst_lib):
        shutil.copy2(src_lib, dst_lib)
        print(f"Copied {lib_name}")

# 2. Generate 80x80 modern cyan icon.png
img = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Surface rounded rect (#131B2A)
draw.rounded_rectangle([(2, 2), (77, 77)], radius=16, fill=(19, 27, 42, 255), outline=(30, 40, 61, 255), width=2)

# Outer glow ring
draw.ellipse([(14, 14), (65, 65)], outline=(56, 189, 248, 60), width=4)

# Lumen Accent Circle (#38BDF8)
draw.ellipse([(18, 18), (61, 61)], outline=(56, 189, 248, 255), width=3)

# Center Diamond / Rocket Chevron
points = [(39, 26), (51, 40), (39, 54), (27, 40)]
draw.polygon(points, fill=(56, 189, 248, 255))
draw.polygon([(39, 31), (47, 40), (39, 49), (31, 40)], fill=(248, 250, 252, 255))

icon_path = os.path.join(APP_DIR, "icon.png")
img.save(icon_path, "PNG")
print(f"Generated {icon_path} successfully.")
