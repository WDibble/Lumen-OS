#!/bin/sh
# Lumen-OS Launcher for VMAC
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
DEFAULT_TARGET="minivmac_libretro.so"

if [ $# -ge 2 ]; then
    exec sh "$DISPATCHER" "$@"
else
    exec sh "$DISPATCHER" "$1" "$DEFAULT_TARGET"
fi
