#!/bin/sh
# Lumen-OS RetroArch Audio Output Auto-Router
# Supports USB DAC, Bluetooth ALSA, and fallback OSS

RA_CFG="/mnt/SDCARD/RetroArch/retroarch.cfg"
SET_CFG="/mnt/SDCARD/System/usr/trimui/scripts/set_ra_cfg.sh"

# Detect USB DAC card index >= 1 (excluding onboard audiocodec and sndhdmi)
USB_CARD=$(awk '
    /^[[:space:]]*[1-9]/ {
        line = tolower($0)
        if (line ~ /(usb|dac|headset|audio)/ && line !~ /(audiocodec|sndhdmi)/) {
            print $1
            exit
        }
    }
' /proc/asound/cards 2>/dev/null)

if [ -n "$USB_CARD" ]; then
    echo "USB DAC detected on card $USB_CARD: RetroArch audio driver set to alsa (hw:$USB_CARD,0)"
    if [ -x "$SET_CFG" ]; then
        "$SET_CFG" "$RA_CFG" "audio_driver" "alsa"
        "$SET_CFG" "$RA_CFG" "audio_device" "hw:$USB_CARD,0"
    fi
elif [ -s "/tmp/btdev_addr" ]; then
    echo "Bluetooth in use: RetroArch audio driver set to alsa (default)"
    if [ -x "$SET_CFG" ]; then
        "$SET_CFG" "$RA_CFG" "audio_driver" "alsa"
        "$SET_CFG" "$RA_CFG" "audio_device" "default"
    fi
else
    echo "Standard audio in use: RetroArch audio driver set to oss"
    if [ -x "$SET_CFG" ]; then
        if ! grep -q 'audio_driver *= *"oss"' "$RA_CFG" 2>/dev/null; then
            "$SET_CFG" "$RA_CFG" "audio_driver" "oss"
        fi
        "$SET_CFG" "$RA_CFG" "audio_device" ""
    fi
fi

if pgrep "mplayer" >/dev/null; then
    CHOICE=$(/mnt/SDCARD/System/bin/presenter --file /mnt/SDCARD/System/resources/Background_Music_choice.json --confirm-button A --no-wrap)
    
    if [ "$CHOICE" = "1" ]; then
        if [ -x "$SET_CFG" ]; then
            "$SET_CFG" "$RA_CFG" "audio_driver" "alsa"
        fi
    elif [ "$CHOICE" = "2" ]; then
        pkill -9 musicserver
        pkill -9 mplayer
        if [ -x "$SET_CFG" ]; then
            if ! grep -q 'audio_driver *= *"oss"' "$RA_CFG" 2>/dev/null; then
                "$SET_CFG" "$RA_CFG" "audio_driver" "oss"
            fi
        fi
    fi
fi
