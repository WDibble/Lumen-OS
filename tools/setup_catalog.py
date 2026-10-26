#!/usr/bin/env python3
"""
Lumen-OS System & Emulator Catalog Generator
Generates clean declarative configurations, launch wrappers, and modern icons
for core gaming platforms.
"""

import json
import os
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = "/Users/dibble/Documents/GitHub/lumen-os"
EMUS_DIR = os.path.join(REPO_ROOT, "Emus")
ROMS_DIR = os.path.join(REPO_ROOT, "Roms")
BIOS_DIR = os.path.join(REPO_ROOT, "BIOS")
APPS_DIR = os.path.join(REPO_ROOT, "Apps")

SYSTEMS = [
    {
        "id": "GBA",
        "label": "Game Boy Advance",
        "color": "38BDF8",
        "exts": "bin|gba|agb|gbz|zip|7z",
        "core": "mgba_libretro.so"
    },
    {
        "id": "GB",
        "label": "Game Boy",
        "color": "A3E635",
        "exts": "gb|dmg|zip|7z",
        "core": "gambatte_libretro.so"
    },
    {
        "id": "GBC",
        "label": "Game Boy Color",
        "color": "F43F5E",
        "exts": "gbc|cgb|zip|7z",
        "core": "gambatte_libretro.so"
    },
    {
        "id": "FC",
        "label": "NES / Famicom",
        "color": "EF4444",
        "exts": "nes|fds|unf|zip|7z",
        "core": "fceumm_libretro.so"
    },
    {
        "id": "SFC",
        "label": "SNES / Super Famicom",
        "color": "818CF8",
        "exts": "sfc|smc|fig|bs|st|zip|7z",
        "core": "snes9x_libretro.so"
    },
    {
        "id": "N64",
        "label": "Nintendo 64",
        "color": "10B981",
        "exts": "n64|v64|z64|zip|7z",
        "core": "mupen64plus_next_libretro.so"
    },
    {
        "id": "NDS",
        "label": "Nintendo DS",
        "color": "F59E0B",
        "exts": "nds|zip|7z",
        "core": "melonds_libretro.so"
    },
    {
        "id": "PS",
        "label": "Sony PlayStation",
        "color": "60A5FA",
        "exts": "chd|pbp|cue|bin|iso|m3u",
        "core": "pcsx_rearmed_libretro.so"
    },
    {
        "id": "PSP",
        "label": "Sony PlayStation Portable",
        "color": "38BDF8",
        "exts": "iso|cso|pbp|chd",
        "core": "ppsspp_libretro.so"
    },
    {
        "id": "MD",
        "label": "Sega Mega Drive / Genesis",
        "color": "0284C7",
        "exts": "md|gen|bin|smd|zip|7z",
        "core": "genesis_plus_gx_libretro.so"
    },
    {
        "id": "MS",
        "label": "Sega Master System",
        "color": "06B6D4",
        "exts": "sms|bin|zip|7z",
        "core": "genesis_plus_gx_libretro.so"
    },
    {
        "id": "GG",
        "label": "Sega Game Gear",
        "color": "F97316",
        "exts": "gg|bin|zip|7z",
        "core": "genesis_plus_gx_libretro.so"
    },
    {
        "id": "DC",
        "label": "Sega Dreamcast",
        "color": "FB923C",
        "exts": "chd|cdi|gdi|iso",
        "core": "flycast_libretro.so"
    },
    {
        "id": "PCE",
        "label": "PC Engine / TurboGrafx-16",
        "color": "EC4899",
        "exts": "pce|sgx|cue|ccd|chd|zip|7z",
        "core": "mednafen_pce_fast_libretro.so"
    },
    {
        "id": "NEOGEO",
        "label": "SNK Neo Geo",
        "color": "EAB308",
        "exts": "zip|7z",
        "core": "fbneo_libretro.so"
    },
    {
        "id": "FBNEO",
        "label": "FinalBurn Neo (Arcade)",
        "color": "14B8A6",
        "exts": "zip|7z",
        "core": "fbneo_libretro.so"
    },
    {
        "id": "MAME",
        "label": "MAME (Arcade)",
        "color": "64748B",
        "exts": "zip|7z|chd",
        "core": "mame2003_plus_libretro.so"
    },
    {
        "id": "CPS1",
        "label": "Capcom Play System 1",
        "color": "E11D48",
        "exts": "zip|7z",
        "core": "fbneo_libretro.so"
    },
    {
        "id": "CPS2",
        "label": "Capcom Play System 2",
        "color": "2563EB",
        "exts": "zip|7z",
        "core": "fbneo_libretro.so"
    },
    {
        "id": "CPS3",
        "label": "Capcom Play System 3",
        "color": "D97706",
        "exts": "zip|7z",
        "core": "fbneo_libretro.so"
    },
    {
        "id": "WSC",
        "label": "WonderSwan Color",
        "color": "A855F7",
        "exts": "ws|wsc|zip|7z",
        "core": "mednafen_wswan_libretro.so"
    },
    {
        "id": "ATARI2600",
        "label": "Atari 2600",
        "color": "CA8A04",
        "exts": "a26|bin|zip|7z",
        "core": "stella2014_libretro.so"
    },
    {
        "id": "PICO",
        "label": "PICO-8",
        "color": "F43F5E",
        "exts": "p8|png|zip",
        "core": "retro8_libretro.so"
    }
]

def generate_system_icon(sys_info, out_path):
    # 120x120 modern squircle icon with supersampling
    scale = 4
    w, h = 120 * scale, 120 * scale
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    hex_color = sys_info["color"]
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Squircle frame (radius: 28px)
    pad = 8 * scale
    radius = 28 * scale
    draw.rounded_rectangle([pad, pad, w - pad, h - pad], radius=radius, fill=(22, 29, 43, 240), outline=(r, g, b, 200), width=3 * scale)
    # Inner light rim (concentric)
    draw.rounded_rectangle([pad + 3*scale, pad + 3*scale, w - pad - 3*scale, h - pad - 3*scale], radius=radius - 3*scale, outline=(255, 255, 255, 25), width=1 * scale)

    # Center text / label
    text = sys_info["id"]
    font_size = 28 * scale if len(text) <= 4 else (22 * scale if len(text) <= 6 else 18 * scale)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", font_size)
    except Exception:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = (h - th) // 2 - 2 * scale

    draw.text((tx, ty), text, fill=(r, g, b, 255), font=font)

    icon = canvas.resize((120, 120), Image.Resampling.LANCZOS)
    icon.save(out_path, "PNG", optimize=True)

def setup_catalog():
    print(f"Setting up {len(SYSTEMS)} core console systems...")
    for sys_info in SYSTEMS:
        sys_id = sys_info["id"]
        emu_path = os.path.join(EMUS_DIR, sys_id)
        rom_path = os.path.join(ROMS_DIR, sys_id)
        os.makedirs(emu_path, exist_ok=True)
        os.makedirs(rom_path, exist_ok=True)

        # 1. Emus/<SYSTEM>/config.json
        cfg = {
            "label": sys_info["label"],
            "icon": "icon.png",
            "background": "bg.png",
            "themecolor": sys_info["color"],
            "launch": "launch.sh",
            "rompath": f"../../Roms/{sys_id}",
            "imgpath": f"../../Imgs/{sys_id}",
            "useswap": 0,
            "shortname": 0,
            "hidebios": 1,
            "extlist": sys_info["exts"],
            "launchlist": [
                {
                    "name": f"Default ({sys_info['core'].replace('_libretro.so', '')})",
                    "launch": "launch.sh"
                }
            ]
        }
        with open(os.path.join(emu_path, "config.json"), "w") as f:
            json.dump(cfg, f, indent=2)

        # 2. Emus/<SYSTEM>/launch.sh
        core_file = sys_info["core"]
        launch_script = f"""#!/bin/sh
# {sys_info['label']} Launcher Wrapper
ROM_PATH="$1"
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "{core_file}"
else
    RA_DIR="/mnt/SDCARD/RetroArch"
    CORE="$RA_DIR/.retroarch/cores/{core_file}"
    if [ -x "$RA_DIR/ra64.trimui" ] && [ -f "$CORE" ]; then
        HOME="$RA_DIR" exec "$RA_DIR/ra64.trimui" -v -L "$CORE" "$ROM_PATH"
    fi
fi
"""
        lpath = os.path.join(emu_path, "launch.sh")
        with open(lpath, "w") as f:
            f.write(launch_script)
        os.chmod(lpath, 0o755)

        # 3. Generate Icon
        icon_path = os.path.join(emu_path, "icon.png")
        generate_system_icon(sys_info, icon_path)

        # 4. Roms/<SYSTEM>/.gitkeep
        with open(os.path.join(rom_path, ".gitkeep"), "w") as f:
            pass

    # 5. BIOS Catalog
    os.makedirs(BIOS_DIR, exist_ok=True)
    bios_readme = """# System BIOS Directory

Place required emulator BIOS files in this directory:

| System | Recommended BIOS File | Description |
| :--- | :--- | :--- |
| **GBA** | `gba_bios.bin` | Game Boy Advance BIOS |
| **PlayStation** | `scph1001.bin` / `scph5501.bin` / `psxonpsp660.bin` | PS1 BIOS |
| **Dreamcast** | `dc/dc_boot.bin`, `dc/dc_flash.bin` | Sega Dreamcast BIOS |
| **Nintendo DS** | `bios7.bin`, `bios9.bin`, `firmware.bin` | Nintendo DS firmware & ARM BIOS |
| **Sega CD** | `bios_CD_U.bin`, `bios_CD_E.bin`, `bios_CD_J.bin` | MegaCD / SegaCD BIOS |
| **Neo Geo** | `neogeo.zip` | Neo Geo MVS/AES BIOS (place in `BIOS/` or ROM folder) |
| **PC Engine CD** | `syscard3.pce` | PC Engine Super CD-ROM2 System Card v3.0 |
"""
    with open(os.path.join(BIOS_DIR, "README.md"), "w") as f:
        f.write(bios_readme)

    # 6. Apps Directory
    apps = ["RetroArch", "FileManager", "SystemTools"]
    for app in apps:
        app_path = os.path.join(APPS_DIR, app)
        os.makedirs(app_path, exist_ok=True)
        with open(os.path.join(app_path, ".gitkeep"), "w") as f:
            pass

    print(f"Catalog setup complete: {len(SYSTEMS)} systems, BIOS directory, and Apps directories configured.")

if __name__ == "__main__":
    setup_catalog()
