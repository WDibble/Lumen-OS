#!/bin/sh
# Lumen-OS Autonomous Low-Battery & Auto-Save Sentinel
# Monitors AXP2202 fuel gauge capacity and ensures state preservation before brownout.

STATE_DIR="/tmp/lumen/state"
PID_FILE="$STATE_DIR/battery_sentinel.pid"
mkdir -p "$STATE_DIR"

HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

get_battery_capacity() {
    for node in /sys/class/power_supply/*/capacity; do
        if [ -f "$node" ]; then
            cat "$node" 2>/dev/null
            return 0
        fi
    done
    echo 100
}

get_battery_status() {
    for node in /sys/class/power_supply/*/status; do
        if [ -f "$node" ]; then
            cat "$node" 2>/dev/null
            return 0
        fi
    done
    echo "Unknown"
}

save_and_shutdown() {
    REASON="$1"
    echo "[battery_sentinel] Emergency shutdown triggered: $REASON"

    # 1. Lower CPU frequency to 1008MHz to eliminate voltage sag / UVLO brownout
    if [ -d "/sys/devices/system/cpu/cpufreq/policy0" ]; then
        echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null || true
        echo 1008000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null || true
    fi

    # 2. Trigger RetroArch state serialization via UDP command port 55355
    RA_PID=$(pgrep -f "ra64.trimui" 2>/dev/null || true)
    if [ -n "$RA_PID" ]; then
        printf 'SAVE_STATE\n' | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
        printf 'SHOW_MSG LOW BATTERY: EMERGENCY SAVE\n' | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
        sleep 2.5
    fi

    # 3. Warning Red LED Flash
    if [ -x "$HW_TOOL" ]; then
        "$HW_TOOL" led --hex EF4444 --cycles 6 --duration 150 2>/dev/null || true
    fi

    # 4. Atomic storage flush
    sync
    sync

    # 5. Graceful termination of active game
    if [ -n "$RA_PID" ]; then
        kill -TERM "$RA_PID" 2>/dev/null || true
        sleep 1
    fi

    # 6. Power off device
    /sbin/poweroff 2>/dev/null || true
}

if [ "$1" = "--save-and-shutdown" ]; then
    save_and_shutdown "Manual request"
    exit 0
fi

# Sentinel Daemon Loop
LOW_COUNT=0
WARNED_15=0
WARNED_10=0

while true; do
    CAP=$(get_battery_capacity)
    STATUS=$(get_battery_status)

    case "$CAP" in (*[!0-9]*|"") CAP=100 ;; esac

    if [ "$STATUS" = "Discharging" ]; then
        # Tier 1 Warning (15%)
        if [ "$CAP" -le 15 ] && [ "$WARNED_15" -eq 0 ]; then
            WARNED_15=1
            [ -x "$HW_TOOL" ] && "$HW_TOOL" led --hex F97316 2>/dev/null || true
            if pgrep -f "ra64.trimui" >/dev/null 2>&1; then
                printf 'SHOW_MSG BATTERY LOW (15%%)\n' | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
            fi
        elif [ "$CAP" -gt 15 ]; then
            WARNED_15=0
        fi

        # Tier 2 Warning (10%)
        if [ "$CAP" -le 10 ] && [ "$WARNED_10" -eq 0 ]; then
            WARNED_10=1
            [ -x "$HW_TOOL" ] && "$HW_TOOL" led --hex EF4444 --cycles 2 2>/dev/null || true
            if pgrep -f "ra64.trimui" >/dev/null 2>&1; then
                printf 'SHOW_MSG BATTERY CRITICAL (10%%) - SAVE SOON\n' | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
            fi
        elif [ "$CAP" -gt 10 ]; then
            WARNED_10=0
        fi

        # Tier 3 Emergency Sentinel (<= 4%)
        if [ "$CAP" -le 4 ]; then
            LOW_COUNT=$((LOW_COUNT + 1))
            # 3 consecutive reads prevents transient load sag from false triggering
            if [ "$LOW_COUNT" -ge 3 ]; then
                save_and_shutdown "Battery capacity <= 4% ($CAP%)"
                exit 0
            fi
        else
            LOW_COUNT=0
        fi
    else
        LOW_COUNT=0
        WARNED_15=0
        WARNED_10=0
    fi

    sleep 30
done
