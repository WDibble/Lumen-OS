#!/bin/sh
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
