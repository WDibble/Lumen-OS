#!/bin/sh
# Lumen-OS Launcher for SATELLAVIEW
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
DEFAULT_TARGET="snes9x_libretro.so"

if [ $# -ge 2 ]; then
    exec sh "$DISPATCHER" "$@"
else
    exec sh "$DISPATCHER" "$1" "$DEFAULT_TARGET"
fi
