#!/bin/sh
# Lumen-OS Headless Syncthing Cloud Saves Service
# Provides seamless headless sync of saves and states with PC/Steam Deck over Wi-Fi.
# Enforces low-memory Go containment (48MB cap, GOGC=25, nice 19).

CONFIG_FILE="/mnt/SDCARD/System/etc/config.json"
LUMEN_CFG="/mnt/SDCARD/System/etc/lumen.json"
SYNCTHING_BIN="/mnt/SDCARD/System/bin/syncthing"
SYNC_DIR="/mnt/SDCARD/System/etc/syncthing"
DATA_DIR="/mnt/SDCARD/System/etc/syncthing/data"
PID_FILE="/tmp/lumen/state/syncthing.pid"

mkdir -p "/tmp/lumen/state"

is_enabled() {
    # Check config.json first
    if [ -f "$CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
        VAL=$(jq -r '.services.syncthing // empty' "$CONFIG_FILE" 2>/dev/null)
        [ "$VAL" = "true" ] && return 0
    fi
    # Fallback to lumen.json
    if [ -f "$LUMEN_CFG" ] && command -v jq >/dev/null 2>&1; then
        VAL=$(jq -r '.["Syncthing"] // 0' "$LUMEN_CFG" 2>/dev/null)
        [ "$VAL" = "1" ] && return 0
    fi
    return 1
}

has_network() {
    # Check if wlan0 or eth0 has an IPv4 address
    if ifconfig 2>/dev/null | grep -A 1 'wlan0' | grep -q 'inet '; then
        return 0
    fi
    return 1
}

start_service() {
    if ! is_enabled; then
        echo "[syncthing] Service is disabled in config.json."
        return 0
    fi

    if [ ! -x "$SYNCTHING_BIN" ]; then
        echo "[syncthing] Binary not found at $SYNCTHING_BIN."
        return 1
    fi

    if ! has_network; then
        echo "[syncthing] No active Wi-Fi connection; deferring startup."
        return 0
    fi

    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "[syncthing] Already running."
        return 0
    fi

    mkdir -p "$SYNC_DIR" "$DATA_DIR" "/mnt/SDCARD/RetroArch/.retroarch/saves" "/mnt/SDCARD/RetroArch/.retroarch/states"

    # Restrict memory footprint for 1GB RAM handheld
    export GOMEMLIMIT=48MiB
    export GOGC=25
    export STNORESTART=1
    export STNOUPGRADE=1
    export STGUIADDRESS="0.0.0.0:8384"

    # Spawn daemon under lowest scheduling priority (nice 19, ionice 3)
    (
        exec nice -n 19 ionice -c 3 "$SYNCTHING_BIN" serve \
            --no-browser \
            --no-restart \
            --no-upgrade \
            --config="$SYNC_DIR" \
            --data="$DATA_DIR" \
            --logflags=0 >/tmp/lumen/log/syncthing.log 2>&1
    ) &
    DAEMON_PID=$!
    echo "$DAEMON_PID" > "$PID_FILE"
    echo "[syncthing] Started with PID $DAEMON_PID (GUI at http://<IP>:8384)."
}

stop_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        [ -n "$PID" ] && kill -TERM "$PID" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    killall -TERM syncthing 2>/dev/null || true
    echo "[syncthing] Stopped."
}

case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
            echo "[syncthing] Running (PID $(cat "$PID_FILE"))."
        else
            echo "[syncthing] Stopped."
        fi
        ;;
    *)
        start_service
        ;;
esac
exit 0
