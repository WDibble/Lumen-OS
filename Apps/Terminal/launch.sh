#!/bin/sh
# Lumen-OS Terminal Launcher
# Enforces POSIX ash compliance, MainUI lifecycle suspension, and FB geometry recovery

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

chmod +x ./SimpleTerminal ./TermSP 2>/dev/null || true

MAINUI_PID=$(pidof MainUI)
WATCHDOG_PID=""

cleanup() {
    # 1. Kill any child processes
    if [ -n "$WATCHDOG_PID" ]; then
        kill "$WATCHDOG_PID" 2>/dev/null || true
    fi
    kill -9 $(pidof gptokeyb2) 2>/dev/null || true

    # 2. Remove stick disable lock
    rm -f /var/trimui_inputd/sticks_disabled 2>/dev/null || true

    # 3. Restore double-buffered virtual framebuffer geometry (polymorphic device restoration)
    if [ -x /mnt/SDCARD/System/bin/next-hw ]; then
        /mnt/SDCARD/System/bin/next-hw display --restore 2>/dev/null || true
    elif [ -x /mnt/SDCARD/System/bin/fbset ]; then
        /mnt/SDCARD/System/bin/fbset -g 1280 720 1280 1440 32 2>/dev/null || true
    elif command -v fbset >/dev/null 2>&1; then
        fbset -g 1280 720 1280 1440 32 2>/dev/null || true
    fi

    # 4. Ensure unblanked
    if [ -w /sys/class/graphics/fb0/blank ]; then
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
    fi

    # 5. Restore terminal cursor
    printf "\033[?25h" 2>/dev/null || true

    # 6. Resume MainUI
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM QUIT HUP

# Freeze MainUI to free CPU and prevent double-render
if [ -n "$MAINUI_PID" ]; then
    kill -SIGSTOP "$MAINUI_PID" 2>/dev/null || true
fi

# Launch watchdog to restore MainUI if script dies unexpectedly
(
    TERMINAL_PPID=$$
    while kill -0 "$TERMINAL_PPID" 2>/dev/null; do
        sleep 2
    done
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
) &
WATCHDOG_PID=$!

export TERM=xterm-256color
export HOME="/mnt/SDCARD"
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/scripts:${PATH:-/bin:/usr/bin:/usr/trimui/bin}"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:-}"

# Fix slowdown caused by inputd analog stick polling in terminal
mkdir -p /var/trimui_inputd 2>/dev/null || true
touch /var/trimui_inputd/sticks_disabled 2>/dev/null || true

# Launch gamepad to keyboard mapper if available
if [ -x /mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 ] && [ -f "$SCRIPT_DIR/resources/keys.gptk" ]; then
    /mnt/SDCARD/Apps/PortMaster/PortMaster/gptokeyb2 -1 "SimpleTerminal" -c "$SCRIPT_DIR/resources/keys.gptk" &
fi

if [ "$#" -gt 0 ]; then
    ./SimpleTerminal "$@"
else
    ./SimpleTerminal
fi
