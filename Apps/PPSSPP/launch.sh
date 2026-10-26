#!/bin/sh
# Sony PlayStation Portable Standalone App Launcher (PPSSPP 1.17.1)
# Strict POSIX ash, zero-NAND mutation, Allwinner 1280x720 framebuffer

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
EMU_DIR="/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1"
CONFIG_FILE="$EMU_DIR/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
EXEC="$EMU_DIR/PPSSPPSDL_gl"
HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

mkdir -p "$EMU_DIR/.config/ppsspp/PSP/SYSTEM" /tmp/lumen/log /tmp/lumen/state

# 1. Geometry & Display setup
fbset -g 1280 720 1280 1440 32 2>/dev/null || true
echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true

# 2. Performance profile
if [ -x "$HW_TOOL" ]; then
    "$HW_TOOL" cpu --profile performance 2>/dev/null || true
fi

# 3. Sanitize and lock configuration
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's/\r$//' "$CONFIG_FILE" 2>/dev/null || true
    if grep -q '^\[Graphics\]' "$CONFIG_FILE"; then
        sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$CONFIG_FILE" 2>/dev/null || true
    fi
    if grep -q '^\[Sound\]' "$CONFIG_FILE"; then
        sed -i '/^\[Sound\]$/,/^\[/ s/GlobalVolume = .*/GlobalVolume = 10/' "$CONFIG_FILE" 2>/dev/null || true
        sed -i '/^\[Sound\]$/,/^\[/ s/AudioMuted = .*/AudioMuted = False/' "$CONFIG_FILE" 2>/dev/null || true
    fi
    if grep -q '^\[Audio\]' "$CONFIG_FILE"; then
        sed -i '/^\[Audio\]$/,/^\[/ s/GlobalVolume = .*/GlobalVolume = 10/' "$CONFIG_FILE" 2>/dev/null || true
        sed -i '/^\[Audio\]$/,/^\[/ s/AudioMuted = .*/AudioMuted = False/' "$CONFIG_FILE" 2>/dev/null || true
    fi
fi

# 4. Suspend MainUI
MAINUI_PID=$(pidof MainUI 2>/dev/null || true)
if [ -n "$MAINUI_PID" ]; then
    kill -SIGSTOP "$MAINUI_PID" 2>/dev/null || true
fi

# 5. Cleanup Trap
cleanup() {
    TRAP_EXIT=$?
    [ -n "$WATCHDOG_PID" ] && kill "$WATCHDOG_PID" 2>/dev/null || true

    if [ -x "$HW_TOOL" ]; then
        "$HW_TOOL" display --restore 2>/dev/null || true
        "$HW_TOOL" cpu --profile normal 2>/dev/null || true
    else
        fbset -g 1280 720 1280 1440 32 2>/dev/null || true
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
    fi

    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
    exit $TRAP_EXIT
}
trap cleanup EXIT INT TERM QUIT HUP

# 6. Execute PPSSPP in background and supervise
cd "$EMU_DIR" || exit 1
export HOME="$EMU_DIR"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$EXEC" &
PPSSPP_PID=$!

(
    while kill -0 $$ 2>/dev/null && kill -0 "$PPSSPP_PID" 2>/dev/null; do
        sleep 1
    done
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
) >/dev/null 2>&1 &
WATCHDOG_PID=$!

wait "$PPSSPP_PID" 2>/dev/null || true
