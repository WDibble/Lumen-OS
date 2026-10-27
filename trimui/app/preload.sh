#!/bin/sh
# Lumen-OS Boot Preload Hook
# Target: Allwinner A133plus (TrimUI Smart Pro)

set -e

# Setup clean tmpfs directory hierarchy
LOG_DIR="/tmp/lumen/log"
mkdir -p "$LOG_DIR" /tmp/lumen/state /tmp/lumen/lock
BOOT_LOG="$LOG_DIR/boot.log"

exec >> "$BOOT_LOG" 2>&1
echo "=== [Lumen-OS] Preload Hook Started: $(date '+%Y-%m-%d %H:%M:%S') ==="

# Export prioritized runtime environment
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/scripts:${PATH:-/bin:/usr/bin:/usr/trimui/bin}"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 1. Check for pending resume-at-boot command
CMD_FILE="/mnt/SDCARD/trimui/app/cmd_to_run.sh"

if [ -f "$CMD_FILE" ]; then
    CONFIG_FILE="/mnt/SDCARD/System/etc/config.json"
    RESUME_ENABLED=1
    if [ -f "$CONFIG_FILE" ]; then
        if command -v jq >/dev/null 2>&1; then
            RESUME_ENABLED=$(jq -r '.resume_at_boot // 1' "$CONFIG_FILE" 2>/dev/null || echo 1)
        fi
    fi

    if [ "$RESUME_ENABLED" = "0" ]; then
        echo "[Lumen-OS] Resume at boot disabled in config. Discarding command."
        rm -f "$CMD_FILE"
        exit 1
    fi

    # Check if MENU button is held down to abort resume
    MENU_PRESSED=0
    if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
        if next-hw button --check MENU 2>/dev/null; then
            MENU_PRESSED=1
        fi
    elif [ -e "/dev/input/event3" ] && command -v evtest >/dev/null 2>&1; then
        evtest --query /dev/input/event3 1 316 >/dev/null 2>&1
        [ $? -eq 10 ] && MENU_PRESSED=1
    fi

    if [ "$MENU_PRESSED" -eq 1 ]; then
        echo "[Lumen-OS] MENU button held during boot. Aborting game resume."
        rm -f "$CMD_FILE"
        sync
        # Visual feedback: flash LEDs blue
        if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
            next-hw led --hex 0000FF --cycles 3 2>/dev/null || true
        fi
        exit 1
    fi

    echo "[Lumen-OS] Executing resumed session: $CMD_FILE"
    TMP_CMD="/tmp/lumen/cmd_to_run.sh"
    cp "$CMD_FILE" "$TMP_CMD"
    rm -f "$CMD_FILE"
    sync
    chmod +x "$TMP_CMD"
    exec "$TMP_CMD"
fi

# 2. Check if MENU button is held down at boot to force fallback to MainUI
MENU_HELD=0
if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
    if /mnt/SDCARD/System/bin/next-hw button --check MENU 2>/dev/null; then
        MENU_HELD=1
    fi
elif [ -e "/dev/input/event3" ] && command -v evtest >/dev/null 2>&1; then
    evtest --query /dev/input/event3 1 316 >/dev/null 2>&1
    [ $? -eq 10 ] && MENU_HELD=1
fi

if [ "$MENU_HELD" -eq 1 ]; then
    echo "[Lumen-OS] RECOVERY MODE: MENU button held at boot. Falling back to stock MainUI."
    if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
        /mnt/SDCARD/System/bin/next-hw led --hex FF8800 --cycles 2 2>/dev/null || true
    fi
    exit 1
fi

# 3. Boot directly into native Lumen Launcher as the default OS interface
LUMEN_SHELL="/mnt/SDCARD/Apps/LumenLauncher/launch.sh"
if [ -x "$LUMEN_SHELL" ]; then
    echo "[Lumen-OS] Booting directly into Lumen Native OS Shell..."
    if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
        /mnt/SDCARD/System/bin/next-hw led --hex 38BDF8 --cycles 1 2>/dev/null || true
    fi
    exec "$LUMEN_SHELL"
fi

echo "=== [Lumen-OS] Preload Hook Completed ==="
exit 0
