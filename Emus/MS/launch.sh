#!/bin/sh
# Sega Master System Launcher Wrapper
ROM_PATH="$1"
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "genesis_plus_gx_libretro.so"
else
    RA_DIR="/mnt/SDCARD/RetroArch"
    CORE="$RA_DIR/.retroarch/cores/genesis_plus_gx_libretro.so"
    if [ -x "$RA_DIR/ra64.trimui" ] && [ -f "$CORE" ]; then
        HOME="$RA_DIR" exec "$RA_DIR/ra64.trimui" -v -L "$CORE" "$ROM_PATH"
    fi
fi
