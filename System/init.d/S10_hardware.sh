#!/bin/sh
# Lumen-OS Init Service: Hardware Initialization

ACTION="${1:-start}"
HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

case "$ACTION" in
    start)
        echo "[S10_hardware] Initializing hardware..."
        if [ -x "$HW_TOOL" ]; then
            # Initialize analog stick LEDs with subtle deep cyan/slate glow
            "$HW_TOOL" led --hex 002244 || true

            # Set balanced default CPU governor
            "$HW_TOOL" cpu --gov ondemand --min 816000 --max 1608000 || true

            # Sync RetroAchievements configuration to retroarch.cfg if present
            CFG="/mnt/SDCARD/System/etc/config.json"
            RA_CFG="/mnt/SDCARD/RetroArch/retroarch.cfg"
            if [ -f "$CFG" ] && [ -f "$RA_CFG" ] && command -v jq >/dev/null 2>&1; then
                CH_EN=$(jq -r '.retroachievements.enabled // false' "$CFG" 2>/dev/null)
                CH_USER=$(jq -r '.retroachievements.username // empty' "$CFG" 2>/dev/null)
                CH_TOKEN=$(jq -r '.retroachievements.token // empty' "$CFG" 2>/dev/null)
                if [ "$CH_EN" = "true" ] && [ -n "$CH_USER" ]; then
                    sed -i 's/^cheevos_enable = .*/cheevos_enable = "true"/' "$RA_CFG" 2>/dev/null || true
                    sed -i "s|^cheevos_username = .*|cheevos_username = \"$CH_USER\"|" "$RA_CFG" 2>/dev/null || true
                    sed -i "s|^cheevos_token = .*|cheevos_token = \"$CH_TOKEN\"|" "$RA_CFG" 2>/dev/null || true
                else
                    sed -i 's/^cheevos_enable = .*/cheevos_enable = "false"/' "$RA_CFG" 2>/dev/null || true
                fi
            fi
        else
            # Sysfs fallback if next-hw binary is missing
            if [ -d "/sys/class/led_anim" ]; then
                echo 1 > /sys/class/led_anim/effect_enable 2>/dev/null || true
                echo "002244" > /sys/class/led_anim/effect_rgb_hex_lr 2>/dev/null || true
                echo 100 > /sys/class/led_anim/max_scale 2>/dev/null || true
            fi
            if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
                echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
                echo 816000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || true
                echo 1608000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || true
            fi
        fi
        ;;
    stop)
        if [ -x "$HW_TOOL" ]; then
            "$HW_TOOL" led --off || true
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
