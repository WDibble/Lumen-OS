#!/bin/sh
# Lumen-OS Audio DAC Sleep De-Pop Guard
# Eliminates acoustic DC step popping on TrimUI Smart Pro stereo micro-speakers
# during suspend/resume cycles via asymmetric muting and capacitive bias settling delays.

STATE_DIR="/tmp/lumen/state"
mkdir -p "$STATE_DIR"
VOL_LOCK="$STATE_DIR/.alsa_vol.lock"

case "$1" in
    sleep|suspend)
        # 1. Save current volume state if not already locked
        if [ ! -f "$VOL_LOCK" ]; then
            amixer get 'Lineout' 2>/dev/null | grep -m1 -o '[0-9]*%' > "$VOL_LOCK" 2>/dev/null || echo "75%" > "$VOL_LOCK"
        fi

        # 2. Asymmetric soft mute: ramp down and mute analog lineout & headphone
        amixer -q set 'Lineout volume' 0 2>/dev/null || true
        amixer -q set 'Lineout' mute 2>/dev/null || true
        amixer -q set 'Headphone' mute 2>/dev/null || true

        # 3. 60ms capacitive discharge dwell to prevent inductive kickback
        usleep 60000 2>/dev/null || sleep 0.06 2>/dev/null || true

        # 4. Trigger kernel suspend-to-RAM
        if [ "$2" != "--no-suspend" ]; then
            echo mem > /sys/power/state 2>/dev/null || true
        fi
        ;;

    wake|resume)
        # 1. 250ms mandatory capacitive bias stabilization dwell
        usleep 250000 2>/dev/null || sleep 0.25 2>/dev/null || true

        # 2. Unmute analog stages
        amixer -q set 'Lineout' unmute 2>/dev/null || true
        amixer -q set 'Headphone' unmute 2>/dev/null || true

        # 3. Restore previous volume from volatile lockfile
        if [ -f "$VOL_LOCK" ]; then
            SAVED_VOL=$(cat "$VOL_LOCK" 2>/dev/null || echo "75%")
            amixer -q set 'Lineout' "$SAVED_VOL" 2>/dev/null || true
            rm -f "$VOL_LOCK"
        else
            amixer -q set 'Lineout' 75% 2>/dev/null || true
        fi
        ;;

    *)
        echo "Usage: $0 {sleep|wake} [--no-suspend]"
        exit 1
        ;;
esac
exit 0
