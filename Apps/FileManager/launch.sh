#!/bin/sh
cd /mnt/SDCARD/Apps/FileManager

export HOME=/mnt/SDCARD/.home
mkdir -p "$HOME"
export LD_LIBRARY_PATH="/mnt/SDCARD/Apps/FileManager/lib:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"

./DinguxCommander
