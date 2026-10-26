#!/bin/sh
# Lumen-OS First Boot Orchestrator
[ -f "/mnt/SDCARD/.lumen_initialized" ] && exit 0

if [ -x "/mnt/SDCARD/System/init.d/S00_oobe.sh" ]; then
    exec /mnt/SDCARD/System/init.d/S00_oobe.sh
fi
exit 0
