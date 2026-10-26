#!/bin/sh
# Lumen-OS Init Bridge
# Executed deterministically by TrimUI runtrimui.sh on system startup

INIT_DIR="/mnt/SDCARD/System/init.d"
LOG_FILE="/tmp/lumen/log/init.log"
mkdir -p /tmp/lumen/log

echo "=== [Lumen-OS] System Init Started: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

if [ -d "$INIT_DIR" ]; then
    # Deterministic numerical order execution of S* scripts
    for script in "$INIT_DIR"/S[0-9][0-9]*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            echo "[Lumen-OS] Starting $script_name..." >> "$LOG_FILE"
            sh "$script" start >> "$LOG_FILE" 2>&1 || echo "[Lumen-OS] Warning: $script_name failed with status $?" >> "$LOG_FILE"
        fi
    done
fi

echo "=== [Lumen-OS] System Init Finished: $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"
