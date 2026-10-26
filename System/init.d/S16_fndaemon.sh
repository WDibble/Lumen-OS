#!/bin/sh
# Lumen-OS Physical FN Switch Hardware Daemon
# Listens for hardware slide switch transitions on /dev/input/event3 (EV_SW code 1).
# Toggles between Turbo Performance (1608MHz + Cyan LED #38BDF8)
# and Balanced Normal (816-1608MHz + Dark Blue LED #002244).

EVDEV="/dev/input/event3"
STATE_DIR="/tmp/lumen/state"
PID_FILE="$STATE_DIR/fndaemon.pid"
mkdir -p "$STATE_DIR"

HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

notify_user() {
    MSG="$1"
    if pgrep -f "ra64.trimui" >/dev/null 2>&1; then
        printf 'SHOW_MSG %s\n' "$MSG" | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
    elif [ -x /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh ] && ! pgrep -f "MainUI" >/dev/null 2>&1; then
        # Standalone emulators or native apps
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$MSG" -t 1 2>/dev/null &
    fi
}

apply_state() {
    STATE="$1"
    DEBOUNCE="$2"
    [ "$DEBOUNCE" = "1" ] && usleep 50000 2>/dev/null || true

    if [ "$STATE" = "1" ]; then
        echo 1 > "$STATE_DIR/fn_state"
        [ -x "$HW_TOOL" ] && "$HW_TOOL" cpu --profile performance 2>/dev/null || true
        [ -x "$HW_TOOL" ] && "$HW_TOOL" led --hex 38BDF8 2>/dev/null || true
        notify_user "TURBO PERFORMANCE (1.6 GHz)"
    else
        echo 0 > "$STATE_DIR/fn_state"
        [ -x "$HW_TOOL" ] && "$HW_TOOL" cpu --profile normal 2>/dev/null || true
        [ -x "$HW_TOOL" ] && "$HW_TOOL" led --hex 0284C7 2>/dev/null || true
        notify_user "BALANCED MODE"
    fi
}

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "[fndaemon] Already running."
        return 0
    fi

    # 1. Read initial steady-state level on boot
    INIT_STATE=0
    if [ -x "$HW_TOOL" ]; then
        if "$HW_TOOL" button --check FN 2>/dev/null; then
            INIT_STATE=1
        fi
    fi
    apply_state "$INIT_STATE" 0

    # 2. Spawn event monitor subshell
    (
        if [ -c "$EVDEV" ] && command -v evtest >/dev/null 2>&1; then
            evtest "$EVDEV" 2>/dev/null | while read -r line; do
                case "$line" in
                    *"type 5 (EV_SW), code 1 (SW_TABLET_MODE), value 1"*)
                        apply_state 1 1
                        ;;
                    *"type 5 (EV_SW), code 1 (SW_TABLET_MODE), value 0"*)
                        apply_state 0 1
                        ;;
                    *"type 1 (EV_KEY), code 1 (KEY_ESC), value 1"*)
                        apply_state 1 1
                        ;;
                    *"type 1 (EV_KEY), code 1 (KEY_ESC), value 0"*)
                        apply_state 0 1
                        ;;
                esac
            done
        fi
    ) >/dev/null 2>&1 &
    DAEMON_PID=$!
    echo "$DAEMON_PID" > "$PID_FILE"
}

case "$1" in
    start)
        start_daemon
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
            echo "[fndaemon] Running (PID $(cat "$PID_FILE")) | State: $(cat "$STATE_DIR/fn_state" 2>/dev/null)"
        else
            echo "[fndaemon] Stopped"
        fi
        ;;
    *)
        start_daemon
        ;;
esac
exit 0
