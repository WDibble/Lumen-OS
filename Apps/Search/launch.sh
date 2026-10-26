#!/bin/sh
# Lumen-OS Cross-Console Game Search
# Fast, D-Pad accessible ROM search across all 112 platforms.

SELECTOR="/mnt/SDCARD/System/bin/selector"
DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"

if [ ! -x "$SELECTOR" ]; then
    echo "Selector tool missing."
    exit 1
fi

cd /mnt/SDCARD/Roms 2>/dev/null || cd /Users/dibble/Documents/GitHub/lumen-os/Roms 2>/dev/null || exit 1

# 1. Letter / Category selection
CHOICE=$("$SELECTOR" -fs 80 -c \
    "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" \
    "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" \
    "0-9" "Recent Games" 2>/dev/null)

CHOICE=$(printf '%s\n' "$CHOICE" | sed 's/^.*: //')

[ -z "$CHOICE" ] && exit 0

if [ "$CHOICE" = "Recent Games" ]; then
    exec /mnt/SDCARD/Apps/Activities/fastlaunch.sh
fi

# 2. Search files matching letter across Roms/*/
if [ "$CHOICE" = "0-9" ]; then
    MATCHES=$(find . -mindepth 2 -maxdepth 2 -type f \( -name "[0-9]*" \) ! -name ".*" 2>/dev/null | sort)
else
    MATCHES=$(find . -mindepth 2 -maxdepth 2 -type f \( -iname "$CHOICE*" -o -iname "The $CHOICE*" \) ! -name ".*" 2>/dev/null | sort)
fi

if [ -z "$MATCHES" ]; then
    if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh" ]; then
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "No titles found starting with '$CHOICE'" -t 2
    fi
    exit 0
fi

# 3. Present matched games in selector preserving spaces and special characters
set --
while IFS= read -r match_line; do
    [ -n "$match_line" ] && set -- "$@" "$match_line"
done <<EOF
$MATCHES
EOF

SELECTED_GAME=$("$SELECTOR" -fs 60 "$@" 2>/dev/null)
SELECTED_GAME=$(printf '%s\n' "$SELECTED_GAME" | sed 's/^.*: //')

[ -z "$SELECTED_GAME" ] && exit 0

# Strip leading ./
CLEAN_PATH="${SELECTED_GAME#./}"
PLATFORM=$(echo "$CLEAN_PATH" | cut -d'/' -f1)
FULL_PATH="/mnt/SDCARD/Roms/$CLEAN_PATH"

if [ -f "/mnt/SDCARD/Emus/$PLATFORM/launch.sh" ]; then
    exec "/mnt/SDCARD/Emus/$PLATFORM/launch.sh" "$FULL_PATH"
else
    exec "$DISPATCHER" "$FULL_PATH"
fi
