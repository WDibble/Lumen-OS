#!/bin/sh
# Lumen-OS Init Service: Triggerhappy Hotkey Daemon (thd)
# Supervised lifecycle for hardware shortcuts on TrimUI Smart Pro

ACTION="${1:-start}"
CONF_FILE="/mnt/SDCARD/System/etc/shortcuts.conf"
PID_FILE="/tmp/lumen/run/thd.pid"
THD_BIN="/mnt/SDCARD/System/bin/thd"

mkdir -p /tmp/lumen/run

resolve_input_nodes() {
    # TrimUI Smart Pro gamepad is consistently on event3; volume buttons on event0.
    # Bind to specific hardware event nodes rather than wildcard event* to prevent
    # infinite event feedback loops with virtual uinput devices (gptokeyb2 / trimui_inputd).
    NODES=""
    if [ -e "/dev/input/event3" ]; then
        NODES="$NODES /dev/input/event3"
    fi
    if [ -e "/dev/input/event0" ]; then
        NODES="$NODES /dev/input/event0"
    fi
    
    # Fallback to dynamic hardware device scan if event3 is absent
    if [ -z "$NODES" ] && [ -f "/proc/bus/input/devices" ]; then
        FOUND=$(grep -E -A 4 "Name=.*(trimui|keys|pad|input)" /proc/bus/input/devices 2>/dev/null | grep -o 'event[0-9]*' | head -n2)
        for dev in $FOUND; do
            [ -e "/dev/input/$dev" ] && NODES="$NODES /dev/input/$dev"
        done
    fi

    # Ultimate fallback if no sysfs device matches
    if [ -z "$NODES" ]; then
        NODES="/dev/input/event*"
    fi
    echo "$NODES"
}

case "$ACTION" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "[S15_hotkeys] thd daemon already running (PID $(cat "$PID_FILE"))."
            exit 0
        fi

        if [ ! -x "$THD_BIN" ]; then
            echo "[S15_hotkeys] Error: thd binary not found at $THD_BIN"
            exit 1
        fi

        if [ ! -f "$CONF_FILE" ]; then
            echo "[S15_hotkeys] Error: shortcuts.conf not found at $CONF_FILE"
            exit 1
        fi

        INPUT_NODES=$(resolve_input_nodes)
        echo "[S15_hotkeys] Starting thd on:$INPUT_NODES"

        "$THD_BIN" --daemon \
                   --triggers "$CONF_FILE" \
                   --pidfile "$PID_FILE" \
                   $INPUT_NODES

        echo "[S15_hotkeys] thd daemon started."
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            echo "[S15_hotkeys] Stopping thd (PID $PID)..."
            kill "$PID" 2>/dev/null || true
            sleep 0.2
            kill -9 "$PID" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
        killall thd 2>/dev/null || true
        echo "[S15_hotkeys] thd stopped."
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "thd running (PID $(cat "$PID_FILE"))"
            exit 0
        else
            echo "thd stopped"
            exit 1
        fi
        ;;
    restart)
        $0 stop
        sleep 0.5
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
