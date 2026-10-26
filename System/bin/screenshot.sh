#!/bin/sh
# Lumen-OS Dual-Mode Screenshot Orchestrator
# Triggers instant screen capture across RetroArch, Standalone Emus, and MainUI

SCREENSHOT_DIR="/mnt/SDCARD/Pictures/screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +'%Y%m%d-%Hh%M-%S')
FILE="${TIMESTAMP}.png"
TARGET="${SCREENSHOT_DIR}/${FILE}"

# 1. Subtle acoustic tactile click feedback
CLICK_SOUND="/mnt/SDCARD/Themes/Lumen/sound/click.wav"
if [ -f "$CLICK_SOUND" ] && command -v aplay >/dev/null 2>&1; then
    aplay -q "$CLICK_SOUND" 2>/dev/null &
fi

# 2. Dual-mode routing: RetroArch UDP network control vs Framebuffer snapshot
if pgrep -f "ra64.trimui" >/dev/null 2>&1; then
    # Send screenshot command to RetroArch UDP socket (default port 55355)
    if command -v netcat >/dev/null 2>&1; then
        echo -n "SCREENSHOT" | netcat -u -w1 127.0.0.1 55355 2>/dev/null || true
    elif command -v nc >/dev/null 2>&1; then
        echo -n "SCREENSHOT" | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
    fi
else
    # Standalone emulator or MainUI capture via fb2png
    if [ -x "/mnt/SDCARD/System/bin/fb2png" ]; then
        /mnt/SDCARD/System/bin/fb2png -p "$TARGET" >/dev/null 2>&1 || true
        sync
    fi
fi
