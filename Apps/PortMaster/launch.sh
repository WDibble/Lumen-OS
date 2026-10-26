#!/bin/sh
# Lumen-OS PortMaster Launcher
# Governed by Handheld Craft Philosophy & Zero NAND Mutation Invariant

set -e
controlfolder="/mnt/SDCARD/Apps/PortMaster/PortMaster"
LOG_FILE="/tmp/lumen/log/portmaster.log"
mkdir -p /tmp/lumen/log /tmp/lumen/mnt

# 1. Environment & Zero NAND isolation
if [ -f "/mnt/SDCARD/System/etc/ex_config" ]; then
    . "/mnt/SDCARD/System/etc/ex_config"
else
    export HOME="/mnt/SDCARD/.home"
    export XDG_CONFIG_HOME="/mnt/SDCARD/.config"
    export XDG_DATA_HOME="/mnt/SDCARD/.local/share"
    export XDG_CACHE_HOME="/tmp/lumen/cache"
    export PYTHONDONTWRITEBYTECODE=1
    export PYTHONPYCACHEPREFIX="/tmp/lumen/pycache"
    export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
    export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

# Clean macOS metadata
rm -f "$controlfolder"/._* "$controlfolder"/config/._* 2>/dev/null || true

# 2. Freeze MainUI & spawn fail-safe watchdog
MAINUI_PID=$(pidof MainUI 2>/dev/null || true)
if [ -n "$MAINUI_PID" ]; then
    kill -SIGSTOP "$MAINUI_PID" 2>/dev/null || true
fi

(
    while kill -0 $$ 2>/dev/null; do
        sleep 1
    done
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
) >/dev/null 2>&1 &
WATCHDOG_PID=$!

# 3. Comprehensive Cleanup Trap (display recovery, gptokeyb2, mounts, MainUI)
cleanup() {
    TRAP_EXIT=$?
    echo "[PortMaster] Teardown initiated..." >> "$LOG_FILE" 2>&1 || true
    kill "$WATCHDOG_PID" 2>/dev/null || true
    killall -9 gptokeyb2 2>/dev/null || true
    umount -l /tmp/lumen/mnt/* 2>/dev/null || true
    losetup -D 2>/dev/null || true

    # Multi-device Framebuffer restoration (Double-buffered MainUI page flipping & offset restoral)
    if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
        /mnt/SDCARD/System/bin/next-hw display --restore 2>/dev/null || true
    else
        fbset -g 1280 720 1280 1440 32 2>/dev/null || true
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
    fi

    # Restore hardware governors & LEDs
    if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
        /mnt/SDCARD/System/bin/next-hw cpu --profile normal 2>/dev/null || true
        /mnt/SDCARD/System/bin/next-hw led --hex 002244 2>/dev/null || true
    fi

    # Resume hotkey daemon & MainUI
    killall -CONT thd 2>/dev/null || true
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
    exit $TRAP_EXIT
}
trap cleanup EXIT INT TERM QUIT HUP

# 4. Pre-launch hardware setup
killall -9 gptokeyb2 2>/dev/null || true
killall -STOP thd 2>/dev/null || true

if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
    /mnt/SDCARD/System/bin/next-hw cpu --profile performance 2>/dev/null || true
    /mnt/SDCARD/System/bin/next-hw led --hex 38BDF8 2>/dev/null || true
fi

# 5. Gamepad configuration
export SDL_GAMECONTROLLERCONFIG_FILE="$controlfolder/gamecontrollerdb.txt"
[ -f "$SDL_GAMECONTROLLERCONFIG_FILE" ] && export SDL_GAMECONTROLLERCONFIG=$(cat "$SDL_GAMECONTROLLERCONFIG_FILE")
export PYSDL2_DLL_PATH="/usr/trimui/lib"
export TERM=linux
CUR_TTY=/dev/tty0
[ -e "$CUR_TTY" ] && chmod 666 "$CUR_TTY" 2>/dev/null || true

cd "$controlfolder"

# Splash indicator
if command -v sdl2imgshow >/dev/null 2>&1 && [ -f "$EX_RESOURCE_PATH/background.png" ]; then
    sdl2imgshow \
        -i "$EX_RESOURCE_PATH/background.png" \
        -f "$EX_RESOURCE_PATH/DejaVuSans.ttf" \
        -s 48 \
        -c "0,0,0" \
        -t "Starting PortMaster" >/dev/null 2>&1 &
    sleep 0.5
    pkill -f sdl2imgshow 2>/dev/null || true
fi

[ -f "$controlfolder/trimui/update.txt" ] && sh "$controlfolder/trimui/update.txt" >> "$LOG_FILE" 2>&1 || true

# 6. Execute PortMaster application loop
rm -f "$controlfolder/.pugwash-reboot"

while true; do
    ./pugwash --debug >> "$LOG_FILE" 2>&1 || true

    if [ ! -f "$controlfolder/.pugwash-reboot" ]; then
        break
    fi
    rm -f "$controlfolder/.pugwash-reboot"
done

if [ -f "$controlfolder/.trimui-refresh" ]; then
    rm -f "$controlfolder/.trimui-refresh"
    [ -f "$controlfolder/trimui/image_smash.txt" ] && sh "$controlfolder/trimui/image_smash.txt" >> "$LOG_FILE" 2>&1 || true
fi
