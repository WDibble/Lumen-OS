#!/bin/sh
# Lumen-OS System Readiness & BIOS Checker Launcher
# Adheres to Handheld Craft Philosophy & Framebuffer Traps

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

chmod +x ./bin/syschecker 2>/dev/null || true

MAINUI_PID=$(pidof MainUI)

cleanup() {
    # Restore double-buffered virtual framebuffer geometry (multi-device)
    if [ -x /mnt/SDCARD/System/bin/next-hw ]; then
        /mnt/SDCARD/System/bin/next-hw display --restore 2>/dev/null || true
    elif [ -x /mnt/SDCARD/System/bin/fbset ]; then
        /mnt/SDCARD/System/bin/fbset -g 1280 720 1280 1440 32 2>/dev/null || true
    elif command -v fbset >/dev/null 2>&1; then
        fbset -g 1280 720 1280 1440 32 2>/dev/null || true
    fi

    if [ -w /sys/class/graphics/fb0/blank ]; then
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
    fi

    printf "\033[?25h" 2>/dev/null || true

    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM QUIT HUP

if [ -n "$MAINUI_PID" ]; then
    kill -SIGSTOP "$MAINUI_PID" 2>/dev/null || true
fi

REPORT_FILE="/tmp/lumen/bios_readiness.txt"
mkdir -p /tmp/lumen 2>/dev/null || true

# Run audit
./bin/syschecker "/mnt/SDCARD/BIOS" > "$REPORT_FILE"

# Present results to handheld user
SELECTOR="/mnt/SDCARD/System/bin/selector"
INFOSCREEN="/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh"
TERMINAL="/mnt/SDCARD/Apps/Terminal/launch.sh"

if [ -x "$SELECTOR" ]; then
    # Parse lines into selector choices
    CHOICES=""
    while IFS= read -r line; do
        case "$line" in
            "===="*) continue ;;
            *"Audit"*) continue ;;
            *"Target:"*) continue ;;
            "") continue ;;
            *)
                # Format for selector
                CHOICE_TEXT=$(echo "$line" | cut -c 1-50)
                set -- "$@" "$CHOICE_TEXT"
                ;;
        esac
    done < "$REPORT_FILE"

    if [ "$#" -gt 0 ]; then
        "$SELECTOR" -t "SYSTEM READINESS (B: Exit)" "$@" >/dev/null 2>&1 || true
    fi
elif [ -x "$TERMINAL" ]; then
    "$TERMINAL" -e "cat '$REPORT_FILE'; echo ''; read -p 'Press Enter or B to exit...' dummy"
elif [ -x "$INFOSCREEN" ]; then
    "$INFOSCREEN" -m "BIOS Audit complete. Check /tmp/lumen/bios_readiness.txt" -t 4
else
    cat "$REPORT_FILE"
fi
