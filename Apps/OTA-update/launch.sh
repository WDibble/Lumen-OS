#!/bin/sh
# Lumen-OS OTA Update Launcher

cleanup() {
    kill -9 $(pidof gptokeyb2) 2>/dev/null || true
    rm -f /tmp/stay_awake 2>/dev/null || true
}
trap cleanup EXIT INT TERM QUIT HUP

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:${LD_LIBRARY_PATH:-}"

echo 1 >/tmp/stay_awake

if [ -x /mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 ]; then
    /mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "Terminal" -c "/mnt/SDCARD/Apps/OTA-update/keys.gptk" &
fi

if [ -x /mnt/SDCARD/Apps/Terminal/launch.sh ]; then
    /mnt/SDCARD/Apps/Terminal/launch.sh -e "/mnt/SDCARD/System/usr/trimui/scripts/ota_update.sh"
fi
