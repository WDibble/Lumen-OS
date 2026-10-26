#!/usr/bin/env python3
"""
Lumen-OS Emulator Porting & Standardization Utility
Ports all missing emulators from Lumen-OS-reference to lumen-os
while enforcing:
1. Zero NAND Mutation Invariant
2. Universal Dispatcher Pattern (System/scripts/launch.sh)
3. Bi-directional argument normalization
4. Standardized config.json schema and valid local icon.png
5. Matching Roms/ directory structure
"""

import os
import sys
import glob
import json
import shutil

REPO_ROOT = "/Users/dibble/Documents/GitHub/lumen-os"
REF_ROOT = "/Users/dibble/Documents/GitHub/Lumen-OS-reference"
EMUS_SRC = os.path.join(REF_ROOT, "Emus")
EMUS_DST = os.path.join(REPO_ROOT, "Emus")
ROMS_DST = os.path.join(REPO_ROOT, "Roms")
ICONS_DIR = os.path.join(REPO_ROOT, "Icons/Default/Emus")

# Systems requiring useswap = 1
SWAP_SYSTEMS = {
    "SATURN", "DAPHNE", "SCUMMVM", "DOS", "ADVMAME", "AMIGA", "AMIGACD", "AMIGACDTV",
    "PORTS", "PICO", "NAOMI", "ATOMISWAVE", "N64", "N64DD", "MAME2003PLUS", "MAME2010",
    "PGM", "OPENBOR", "JAVA", "DOOM", "PC98", "X68000", "PANASONIC", "SEGA32X", "SEGACD"
}

# Standalone emulators that retain their custom launcher logic
STANDALONE_SYSTEMS = {
    "SATURN", "DAPHNE", "OPENBOR", "SCUMMVM", "JAVA", "DOOM", "MSX2", "ADVMAME", "PICO",
    "MUSIC", "VIDEOS", "PORTS", "_Scraper", "_SystemTools", "_BootLogo"
}

def get_libretro_core_from_ref(emu_name, ref_dir):
    """Detect the default Libretro core referenced by the reference launch script."""
    launch_candidates = [
        os.path.join(ref_dir, "launch.sh"),
        os.path.join(ref_dir, "default.sh"),
        os.path.join(ref_dir, f"{emu_name.lower()}.sh")
    ]
    for candidate in launch_candidates:
        if os.path.isfile(candidate):
            try:
                with open(candidate, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    import re
                    match = re.search(r'([a-zA-Z0-9_\-]+_libretro\.so)', content)
                    if match:
                        return match.group(1)
            except Exception:
                pass
    return None

def port_all():
    ref_entries = sorted([e for e in os.listdir(EMUS_SRC) if not e.startswith('.')])
    next_entries = set(os.listdir(EMUS_DST))
    
    missing = [e for e in ref_entries if e not in next_entries]
    print(f"Total reference emulators: {len(ref_entries)}")
    print(f"Already in next: {len(next_entries)}")
    print(f"To port: {len(missing)}")
    
    for emu in missing:
        src_path = os.path.join(EMUS_SRC, emu)
        dst_path = os.path.join(EMUS_DST, emu)
        
        # 1. Copy directory tree
        shutil.copytree(src_path, dst_path)
        
        # 2. Process config.json
        cfg_file = os.path.join(dst_path, "config.json")
        cfg_data = {}
        if os.path.isfile(cfg_file):
            try:
                with open(cfg_file, "r", encoding="utf-8") as f:
                    cfg_data = json.load(f)
            except Exception as e:
                print(f"[{emu}] Warning parsing config.json: {e}")
                cfg_data = {}
        
        # Ensure standard keys
        if "label" not in cfg_data:
            cfg_data["label"] = emu
        cfg_data["launch"] = "launch.sh"
        cfg_data["rompath"] = f"../../Roms/{emu}"
        cfg_data["imgpath"] = f"../../Imgs/{emu}"
        cfg_data["useswap"] = 1 if emu in SWAP_SYSTEMS else cfg_data.get("useswap", 0)
        cfg_data["shortname"] = cfg_data.get("shortname", 0)
        cfg_data["hidebios"] = 1
        if "extlist" not in cfg_data:
            cfg_data["extlist"] = "zip|7z"
        if "launchlist" not in cfg_data or not isinstance(cfg_data["launchlist"], list):
            cfg_data["launchlist"] = [{"name": "Default", "launch": "launch.sh"}]
        
        # Ensure local icon.png
        icon_dst = os.path.join(dst_path, "icon.png")
        if not os.path.isfile(icon_dst):
            # Try to copy from Icons/Default/Emus
            icon_candidates = [
                os.path.join(ICONS_DIR, f"{emu}.png"),
                os.path.join(ICONS_DIR, f"{emu.upper()}.png"),
                os.path.join(ICONS_DIR, f"{emu.lower()}.png"),
                os.path.join(ICONS_DIR, f"{emu}-alt.png"),
                os.path.join(src_path, f"{emu}.png"),
                os.path.join(src_path, "icon.png")
            ]
            for cand in icon_candidates:
                if os.path.isfile(cand):
                    shutil.copy2(cand, icon_dst)
                    break
        
        cfg_data["icon"] = "icon.png"
        
        # Write clean config.json
        with open(cfg_file, "w", encoding="utf-8") as f:
            json.dump(cfg_data, f, indent=2)
            f.write("\n")
            
        # 3. Process launch.sh
        launch_file = os.path.join(dst_path, "launch.sh")
        if emu == "_BootLogo":
            # Safe Zero NAND BootLogo launcher
            with open(launch_file, "w", encoding="utf-8") as f:
                f.write("""#!/bin/sh
# Lumen-OS Safe Boot Splash Selector (Zero NAND Mutation)
# Internal flash (MTD/eMMC) mutation is prohibited to prevent device bricking.
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

if [ -f "$1" ]; then
    mkdir -p /mnt/SDCARD/System/res
    cp "$1" /mnt/SDCARD/System/res/boot.bmp
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "SD userspace boot splash updated!" -t 2
else
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Firmware MTD flashing is disabled in Lumen-OS." -t 3
fi
""")
        elif emu not in STANDALONE_SYSTEMS:
            # Libretro Core platform: Route to System/scripts/launch.sh
            core = get_libretro_core_from_ref(emu, src_path)
            if not core:
                # Fallback to fbneo or fceumm or similar if needed
                core = "fbneo_libretro.so"
            with open(launch_file, "w", encoding="utf-8") as f:
                f.write(f"""#!/bin/sh
# Lumen-OS Launcher for {emu}
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
DEFAULT_TARGET="{core}"

if [ $# -ge 2 ]; then
    exec sh "$DISPATCHER" "$@"
else
    exec sh "$DISPATCHER" "$1" "$DEFAULT_TARGET"
fi
""")
        else:
            # Standalone platform: ensure launch.sh exists
            if not os.path.isfile(launch_file):
                # If default.sh exists, link or wrap it
                if os.path.isfile(os.path.join(dst_path, "default.sh")):
                    with open(launch_file, "w", encoding="utf-8") as f:
                        f.write("""#!/bin/sh
cd "$(dirname "$0")"
exec ./default.sh "$@"
""")
        
        # Ensure executable permission
        if os.path.isfile(launch_file):
            os.chmod(launch_file, 0o755)
            
        # 4. Create matching Roms directory
        rom_dir = os.path.join(ROMS_DST, emu)
        os.makedirs(rom_dir, exist_ok=True)
        keep_file = os.path.join(rom_dir, ".keep")
        if not os.path.isfile(keep_file):
            with open(keep_file, "w", encoding="utf-8") as f:
                f.write(f"# Lumen-OS ROM folder for {emu}\n")
                
        print(f"Successfully ported {emu}")

if __name__ == "__main__":
    port_all()
