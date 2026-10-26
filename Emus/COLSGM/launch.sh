#!/bin/sh
# Lumen-OS Launcher for COLSGM
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
DEFAULT_TARGET="gearcoleco_libretro.so"

if [ $# -ge 2 ]; then
    exec sh "$DISPATCHER" "$@"
else
    exec sh "$DISPATCHER" "$1" "$DEFAULT_TARGET"
fi
