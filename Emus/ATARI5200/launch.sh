#!/bin/sh
# Lumen-OS Launcher for ATARI5200
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
DEFAULT_TARGET="a5200_libretro.so"

if [ $# -ge 2 ]; then
    exec sh "$DISPATCHER" "$@"
else
    exec sh "$DISPATCHER" "$1" "$DEFAULT_TARGET"
fi
