#!/bin/sh
# Lumen-OS Orphaned Cover Art Removal Utility
# Scans Imgs/ against Roms/ and safely moves unlinked images to .trash/Imgs/
# Uses exact filename comparisons to prevent bracket globbing collisions ([!], [v1.0])

INFOSCREEN="/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh"
TRASH_DIR="/mnt/SDCARD/.trash/Imgs"
mkdir -p "$TRASH_DIR" /tmp/lumen/state

if [ -x "$INFOSCREEN" ]; then
    "$INFOSCREEN" -m "Scanning for Orphaned Cover Art..." -t 2
fi

TOTAL_MOVED=0
TMP_ROMS_LIST="/tmp/lumen/state/active_rom_stems.txt"

for img_sys in /mnt/SDCARD/Imgs/*/; do
    [ -d "$img_sys" ] || continue
    sys_name=$(basename "$img_sys")
    rom_sys="/mnt/SDCARD/Roms/$sys_name"

    [ -d "$rom_sys" ] || continue

    > "$TMP_ROMS_LIST"
    for r in "$rom_sys"/*; do
        [ -f "$r" ] || continue
        r_name=$(basename "$r")
        r_stem="${r_name%.*}"
        echo "$r_stem" >> "$TMP_ROMS_LIST"
    done

    for img in "$img_sys"/*; do
        [ -f "$img" ] || continue
        img_name=$(basename "$img")
        img_stem="${img_name%.*}"

        if ! grep -F -x -q "$img_stem" "$TMP_ROMS_LIST" 2>/dev/null; then
            dest_dir="$TRASH_DIR/$sys_name"
            mkdir -p "$dest_dir"
            mv -f "$img" "$dest_dir/"
            TOTAL_MOVED=$(( TOTAL_MOVED + 1 ))
        fi
    done
done

rm -f "$TMP_ROMS_LIST"
sync

if [ -x "$INFOSCREEN" ]; then
    "$INFOSCREEN" -m "Completed: $TOTAL_MOVED images moved to .trash/Imgs" -k "A B" -t 5
fi
