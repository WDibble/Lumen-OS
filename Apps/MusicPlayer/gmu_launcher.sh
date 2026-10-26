#!/bin/sh
export LD_LIBRARY_PATH=/mnt/SDCARD/System/lib/:/lib:/lib64:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/lib:$LD_LIBRARY_PATH

settings_file="/mnt/SDCARD/Apps/MusicPlayer/gmu.settings.conf"
first_run_file="/mnt/SDCARD/Apps/MusicPlayer/FirstRunDone"

cd /mnt/SDCARD/Apps/MusicPlayer

/mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 "gmu.bin" -c "/mnt/SDCARD/Apps/MusicPlayer/trimui_smart_pro.gptk" &
GPTOKEYB_PID=$!
sleep 0.4

# Dedicated triggerhappy for GMU LCD switch-off key combination (only on physical event3)
/mnt/SDCARD/System/bin/thd --triggers /mnt/SDCARD/Apps/MusicPlayer/thd.conf /dev/input/event3 &
GMU_THD_PID=$!

cleanup() {
    rm -f /tmp/stay_awake
    [ -n "$GPTOKEYB_PID" ] && kill -TERM "$GPTOKEYB_PID" 2>/dev/null
    [ -n "$GMU_THD_PID" ] && kill -TERM "$GMU_THD_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

echo 1 >/tmp/stay_awake
HOME=/mnt/SDCARD/Apps/MusicPlayer /mnt/SDCARD/Apps/MusicPlayer/gmu.bin -c gmu.settings.conf
rm -f /tmp/stay_awake

cleanup

# Check if the FirstRunDone file exists
if ! [ -f "$first_run_file" ]; then
    sed -i 's/^Gmu.FirstRun=.*/Gmu.FirstRun=no/' "$settings_file"
    touch "$first_run_file"
fi

sync
