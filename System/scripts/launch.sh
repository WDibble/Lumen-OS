#!/bin/sh
# Lumen-OS Universal Emulator Dispatcher
# Usage: launch.sh "<ROM_PATH>" [CORE_OR_STANDALONE_EXEC]
# Supports bi-directional argument ordering for MainUI standard and Options [X] launchlist.

ARG1="$1"
ARG2="$2"
LOG_FILE="/tmp/lumen/log/launch.log"
STATE_DIR="/tmp/lumen/state"
XDG_DIR="/tmp/lumen/xdg"

mkdir -p /tmp/lumen/log "$STATE_DIR" "$XDG_DIR"

# Bi-directional Argument Normalization
if [ -f "$ARG1" ]; then
    ROM_PATH="$ARG1"
    TARGET_PARAM="$ARG2"
elif [ -f "$ARG2" ]; then
    ROM_PATH="$ARG2"
    TARGET_PARAM="$ARG1"
else
    ROM_PATH="$ARG1"
    TARGET_PARAM="$ARG2"
fi

echo "=== [Lumen-OS] Launching ROM: $ROM_PATH ($(date '+%Y-%m-%d %H:%M:%S')) ===" >> "$LOG_FILE"
echo "Launch Session: ROM=$ROM_PATH | Target=$TARGET_PARAM" >> "$LOG_FILE"

if [ -z "$ROM_PATH" ] || [ ! -f "$ROM_PATH" ]; then
    echo "[Lumen-OS] Error: ROM file not found or empty: $ROM_PATH" >> "$LOG_FILE"
    exit 1
fi

HW_TOOL="/mnt/SDCARD/System/bin/next-hw"
RA_DIR="/mnt/SDCARD/RetroArch"

# Environment Invariants (Zero NAND mutation)
export HOME="$RA_DIR"
export XDG_CONFIG_HOME="$XDG_DIR"
export XDG_DATA_HOME="$XDG_DIR"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 1. Save pre-launch CPU state
CPU0="/sys/devices/system/cpu/cpu0/cpufreq"
if [ -d "$CPU0" ]; then
    cat "$CPU0/scaling_governor" > "$STATE_DIR/prev_governor" 2>/dev/null || true
    cat "$CPU0/scaling_min_freq" > "$STATE_DIR/prev_min_freq" 2>/dev/null || true
    cat "$CPU0/scaling_max_freq" > "$STATE_DIR/prev_max_freq" 2>/dev/null || true
fi

# 2. Freeze MainUI
MAINUI_PID=$(pidof MainUI 2>/dev/null || true)
if [ -n "$MAINUI_PID" ]; then
    echo "[Lumen-OS] Suspending MainUI (PID $MAINUI_PID)..." >> "$LOG_FILE"
    kill -SIGSTOP "$MAINUI_PID" 2>/dev/null || true
fi

# 3. Independent Watchdog: Guarantees MainUI resumption on OOM-killer / SIGKILL
(
    while kill -0 $$ 2>/dev/null; do
        sleep 1
    done
    if [ -n "$MAINUI_PID" ]; then
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi
) >/dev/null 2>&1 &
WATCHDOG_PID=$!

# 4. Cleanup Trap for Clean Teardown
cleanup() {
    TRAP_EXIT=$?
    echo "[Lumen-OS] Post-game teardown initiated..." >> "$LOG_FILE"

    # Terminate background input mappers
    killall -9 gptokeyb2 2>/dev/null || true

    # Terminate watchdog
    kill "$WATCHDOG_PID" 2>/dev/null || true

    # Framebuffer restoration (Multi-device dynamic geometry & unblank)
    if [ -x "$HW_TOOL" ]; then
        "$HW_TOOL" display --restore 2>/dev/null || true
    else
        fbset -g 1280 720 1280 1440 32 2>/dev/null || true
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null || true
    fi

    # Restore CPU governor
    if [ -x "$HW_TOOL" ]; then
        if [ -f "$STATE_DIR/prev_governor" ]; then
            PREV_GOV=$(cat "$STATE_DIR/prev_governor")
            PREV_MIN=$(cat "$STATE_DIR/prev_min_freq")
            PREV_MAX=$(cat "$STATE_DIR/prev_max_freq")
            "$HW_TOOL" cpu --gov "$PREV_GOV" --min "$PREV_MIN" --max "$PREV_MAX" 2>/dev/null || true
        else
            "$HW_TOOL" cpu --profile normal 2>/dev/null || true
        fi
        # Restore theme LED glow
        "$HW_TOOL" led --hex 002244 2>/dev/null || true
    fi

    # Resume triggerhappy background daemon
    killall -CONT thd 2>/dev/null || true

    # Resume background syncthing cloud sync
    pkill -CONT syncthing 2>/dev/null || true

    # Resume MainUI
    if [ -n "$MAINUI_PID" ]; then
        echo "[Lumen-OS] Resuming MainUI (PID $MAINUI_PID)..." >> "$LOG_FILE"
        kill -SIGCONT "$MAINUI_PID" 2>/dev/null || true
    fi

    echo "=== [Lumen-OS] Session Ended ===" >> "$LOG_FILE"
    exit $TRAP_EXIT
}

trap cleanup EXIT INT TERM QUIT HUP

# 5. Pause triggerhappy hotkey daemon to prevent shortcut collision during gameplay
killall -STOP thd 2>/dev/null || true
pkill -STOP syncthing 2>/dev/null || true

# 6. Set performance profile for gameplay
if [ -x "$HW_TOOL" ]; then
    "$HW_TOOL" cpu --profile performance 2>/dev/null || true
    "$HW_TOOL" led --hex 38BDF8 2>/dev/null || true
fi

# 7. Execute Target Runner
if [ -n "$TARGET_PARAM" ] && [ -x "$TARGET_PARAM" ]; then
    # Standalone executable binary (e.g. PPSSPP, Drastic, Mupen64plus, Flycast)
    echo "[Lumen-OS] Launching standalone executable: $TARGET_PARAM" >> "$LOG_FILE"
    "$TARGET_PARAM" "$ROM_PATH"
elif [ -n "$TARGET_PARAM" ] && [ "${TARGET_PARAM%.so}" != "$TARGET_PARAM" ]; then
    # Libretro Core (either full path or filename)
    CORE_PATH="$TARGET_PARAM"
    if [ ! -f "$CORE_PATH" ]; then
        CORE_PATH="$RA_DIR/.retroarch/cores/$TARGET_PARAM"
    fi
    if [ ! -f "$CORE_PATH" ]; then
        echo "[Lumen-OS] Error: Libretro core not found: $CORE_PATH" >> "$LOG_FILE"
        exit 2
    fi
    echo "[Lumen-OS] Launching RetroArch core: $CORE_PATH" >> "$LOG_FILE"
    cd "$RA_DIR"
    "$RA_DIR/ra64.trimui" -v -L "$CORE_PATH" "$ROM_PATH" >> "$LOG_FILE" 2>&1 || true
elif [ -z "$TARGET_PARAM" ] && [ -x "$RA_DIR/ra64.trimui" ]; then
    # Default fallback when no core specified: mGBA
    CORE_PATH="$RA_DIR/.retroarch/cores/mgba_libretro.so"
    echo "[Lumen-OS] Default RetroArch launch: $CORE_PATH" >> "$LOG_FILE"
    cd "$RA_DIR"
    "$RA_DIR/ra64.trimui" -v -L "$CORE_PATH" "$ROM_PATH" >> "$LOG_FILE" 2>&1 || true
else
    echo "[Lumen-OS] Error: No runner available for $ROM_PATH (Target: $TARGET_PARAM)" >> "$LOG_FILE"
    exit 1
fi
