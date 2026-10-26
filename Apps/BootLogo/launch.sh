#!/bin/sh
# Lumen-OS BootLogo Generator (Zero NAND Safe)
# Safely generates thumbnails and directs MainUI to BootLogo selector

src_dir="/mnt/SDCARD/Apps/BootLogo/Images_1280x720/"
dest_dir="/mnt/SDCARD/Apps/BootLogo/Thumbnails/"

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:-}"

mkdir -p "$dest_dir"
rm -f ./GoBackTo_Apps.json
[ -f /tmp/state.json ] && cp /tmp/state.json ./GoBackTo_Apps.json
cp ./GoTo_Bootlogo_List.json /tmp/state.json

find "$dest_dir" -type f ! -name "- Default Trimui.png" -exec rm -f {} + 2>/dev/null || true
sync

if [ -x /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Generating thumbnails..." -fs 50 2>/dev/null || true
fi

# Create thumbnails using GraphicsMagick if available
if [ -x /mnt/SDCARD/System/bin/gm ]; then
    find "$src_dir" -type f -name "*.bmp" | while read -r bmp_file; do
        filename=$(basename "$bmp_file")
        if [ "$filename" != "- Default Trimui.bmp" ]; then
            png_dest="$dest_dir/${filename%.bmp}.png"
            if [ ! -f "$png_dest" ]; then
                /mnt/SDCARD/System/bin/gm convert "$bmp_file" -resize 300x\> "$png_dest" 2>/dev/null || true
            fi
        fi
    done
fi
sync

rm -f "$dest_dir/Thumbnails_cache7.db"
sync
exit 0
