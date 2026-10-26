#!/bin/sh
# Lumen-OS StartTab Switcher (FW 1.1.0 State Schema)
# Strictly adheres to two-element array: type 48 (homepage) + type 0 (tab)

STATE_FILE="/tmp/state.json"
CONFIG_FILE="/mnt/SDCARD/System/etc/lumen.json"

TAB_ARG="$1"

case "$TAB_ARG" in
    [0-9]*)
        TAB_INDEX="$TAB_ARG"
        ;;
    "emus"|"emulators"|"Emu"|"EMU")
        TAB_INDEX=0
        ;;
    "apps"|"Apps"|"APP")
        TAB_INDEX=1
        ;;
    "favs"|"favorites"|"Favorites")
        TAB_INDEX=2
        ;;
    "history"|"History")
        TAB_INDEX=3
        ;;
    *)
        if [ -f "$CONFIG_FILE" ] && [ -x "/mnt/SDCARD/System/bin/jq" ]; then
            CONFIG_VAL=$(/mnt/SDCARD/System/bin/jq -r '.["START TAB"] // .["start_tab"] // 0' "$CONFIG_FILE" 2>/dev/null || echo "0")
            case "$CONFIG_VAL" in
                [0-9]*) TAB_INDEX="$CONFIG_VAL" ;;
                *) TAB_INDEX=0 ;;
            esac
        else
            TAB_INDEX=0
        fi
        ;;
esac

# Clamp index to 0..4
if [ -z "$TAB_INDEX" ] || [ "$TAB_INDEX" -lt 0 ] 2>/dev/null; then
    TAB_INDEX=0
elif [ "$TAB_INDEX" -gt 4 ] 2>/dev/null; then
    TAB_INDEX=4
fi

TMP_STATE="/tmp/state.json.tmp.$$"

cat <<EOF > "$TMP_STATE"
[
  {
    "type": 48,
    "index": 0
  },
  {
    "type": 0,
    "index": $TAB_INDEX
  }
]
EOF

mv -f "$TMP_STATE" "$STATE_FILE"
sync
echo "StartTab set to index $TAB_INDEX"
