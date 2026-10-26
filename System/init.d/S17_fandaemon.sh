#!/bin/sh
# Lumen-OS Active Cooling & Fan Sentinel Daemon (TSP-S / Fan Hardware)
# Monitors SoC temperature and enforces hysteresis cooling curve.
# Passive devices exit immediately with code 0.

STATE_DIR="/tmp/lumen/hardware"
PID_FILE="$STATE_DIR/fandaemon.pid"
mkdir -p "$STATE_DIR"

HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

# Check if model has fan
[ -x "$HW_TOOL" ] && "$HW_TOOL" detect >/dev/null 2>&1 || true
if [ -f "$STATE_DIR/hardware.env" ]; then
    . "$STATE_DIR/hardware.env"
fi

if [ "${HAS_FAN:-0}" -ne 1 ]; then
    # Passive device (TSP, Brick, Smart): exit cleanly
    echo "STATUS=passive_device" > "$STATE_DIR/fan_state"
    exit 0
fi

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "[fandaemon] Already running."
        return 0
    fi

    (
        echo $$ > "$PID_FILE"
        CURRENT_PWM=0
        LAST_DOWN_TIME=0

        while true; do
            # Read profile
            PROFILE=$(cat "$STATE_DIR/fan_profile" 2>/dev/null || echo "auto")
            TEMP=$("$HW_TOOL" fan --get-temp 2>/dev/null || echo 45)
            case "$TEMP" in (*[!0-9]*|"") TEMP=45 ;; esac

            NOW=$(date +%s 2>/dev/null || echo 0)

            TARGET_PWM=0

            case "$PROFILE" in
                off)
                    TARGET_PWM=0
                    # Safety thermal override
                    [ "$TEMP" -gt 75 ] && TARGET_PWM=255
                    ;;
                quiet)
                    if [ "$TEMP" -ge 75 ]; then
                        TARGET_PWM=255
                    elif [ "$TEMP" -ge 65 ]; then
                        TARGET_PWM=140
                    elif [ "$TEMP" -ge 55 ]; then
                        TARGET_PWM=64
                    else
                        TARGET_PWM=0
                    fi
                    ;;
                performance)
                    if [ "$TEMP" -ge 70 ]; then
                        TARGET_PWM=255
                    elif [ "$TEMP" -ge 58 ]; then
                        TARGET_PWM=190
                    else
                        TARGET_PWM=115
                    fi
                    ;;
                max)
                    TARGET_PWM=255
                    ;;
                auto|balanced|*)
                    # Dual-threshold Schmitt trigger curve with hysteresis
                    if [ "$TEMP" -ge 75 ]; then
                        # Emergency thermal ceiling
                        TARGET_PWM=255
                    elif [ "$TEMP" -ge 68 ]; then
                        TARGET_PWM=180
                    elif [ "$TEMP" -ge 58 ]; then
                        TARGET_PWM=110
                    elif [ "$TEMP" -ge 50 ]; then
                        TARGET_PWM=50
                    else
                        # Under 50C: fan off
                        TARGET_PWM=0
                    fi
                    ;;
            esac

            # Apply dwell dampening on step-down (minimum 8s dwell)
            if [ "$TARGET_PWM" -lt "$CURRENT_PWM" ]; then
                ELAPSED=$(( NOW - LAST_DOWN_TIME ))
                if [ "$ELAPSED" -ge 8 ]; then
                    CURRENT_PWM="$TARGET_PWM"
                    LAST_DOWN_TIME="$NOW"
                    "$HW_TOOL" fan --set "$CURRENT_PWM"
                fi
            else
                # Step-up is instant
                if [ "$TARGET_PWM" -ne "$CURRENT_PWM" ]; then
                    CURRENT_PWM="$TARGET_PWM"
                    LAST_DOWN_TIME="$NOW"
                    "$HW_TOOL" fan --set "$CURRENT_PWM"
                fi
            fi

            echo "PROFILE=$PROFILE PWM=$CURRENT_PWM TEMP=$TEMP" > "$STATE_DIR/fan_state"
            sleep 4
        done
    ) &
    echo "[fandaemon] Started PID $(cat "$PID_FILE" 2>/dev/null)"
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        [ -n "$PID" ] && kill -TERM "$PID" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    # Turn off fan on stop
    [ -x "$HW_TOOL" ] && "$HW_TOOL" fan --set 0 2>/dev/null || true
}

case "${1:-start}" in
    start)   start_daemon ;;
    stop)    stop_daemon ;;
    restart) stop_daemon; sleep 1; start_daemon ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
            cat "$STATE_DIR/fan_state" 2>/dev/null || echo "Running"
        else
            echo "Stopped"
        fi
        ;;
    *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac

exit 0
