#!/bin/sh
# Lumen-OS Battery Sentinel Service
# Spawns battery_sentinel.sh in background to protect against brownout data corruption.

PID_FILE="/tmp/lumen/state/battery_sentinel.pid"

case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
            echo "[battery] Sentinel already active."
            exit 0
        fi
        /mnt/SDCARD/System/bin/battery_sentinel.sh >/dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "[battery] Sentinel started (PID $!)."
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
            rm -f "$PID_FILE"
            echo "[battery] Sentinel stopped."
        fi
        ;;
    *)
        sh "$0" start
        ;;
esac
exit 0
