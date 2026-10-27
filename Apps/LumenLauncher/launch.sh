#!/bin/sh
# Lumen Native Launcher Trampoline & Execution Supervisor
# Enforces rapid-crash loop protection, CPU scaling, and dispatch loop

LAUNCHER_DIR="/mnt/SDCARD/Apps/LumenLauncher"
LOG_DIR="/tmp/lumen/log"
CRASH_LOG="$LOG_DIR/launcher_crash.log"
CRASH_TS_FILE="/tmp/lumen_launcher_crash_ts"
EXEC_CFG="/tmp/lumen_exec.cfg"

mkdir -p "$LOG_DIR"

# 1. Rapid-Crash Protection Guard (max 3 crashes within 5 seconds)
NOW=$(date +%s)
RAPID_CRASH_COUNT=0
if [ -f "$CRASH_TS_FILE" ]; then
    while IFS= read -r ts; do
        if [ $(( NOW - ts )) -le 5 ]; then
            RAPID_CRASH_COUNT=$(( RAPID_CRASH_COUNT + 1 ))
        fi
    done < "$CRASH_TS_FILE"
fi

if [ "$RAPID_CRASH_COUNT" -ge 3 ]; then
    echo "[CRITICAL] Rapid crash loop detected ($RAPID_CRASH_COUNT crashes). Exiting to MainUI." >> "$CRASH_LOG"
    rm -f "$CRASH_TS_FILE"
    exit 1
fi

# 2. Hardware profile optimization
if [ -x "/mnt/SDCARD/System/bin/next-hw" ]; then
    /mnt/SDCARD/System/bin/next-hw cpu --profile performance 2>/dev/null
fi

# 3. Environment & Runtime configuration
export LD_LIBRARY_PATH="$LAUNCHER_DIR/libs:$LAUNCHER_DIR/libs.aarch64:/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"
LOVE_BIN="$LAUNCHER_DIR/bin/love.aarch64"
if [ ! -x "$LOVE_BIN" ]; then
    LOVE_BIN="/mnt/SDCARD/Apps/PortMaster/PortMaster/runtimes/love_11.5/love.aarch64"
fi

# 4. Master Supervisor Loop
while true; do
    START_TIME=$(date +%s)
    rm -f "$EXEC_CFG"

    # Run Love2D Native Launcher
    "$LOVE_BIN" "$LAUNCHER_DIR" >> "$LOG_DIR/launcher.log" 2>&1
    EXIT_CODE=$?

    END_TIME=$(date +%s)

    # Exit Code 10: Dispatch Trampoline
    if [ "$EXIT_CODE" -eq 10 ]; then
        if [ -f "$EXEC_CFG" ]; then
            . "$EXEC_CFG"
            rm -f "$EXEC_CFG"

            if [ -n "$ROM" ] && [ -x "$TARGET" ]; then
                echo "[LumenLauncher] Dispatching: $TARGET for $ROM" >> "$LOG_DIR/launch.log"
                /mnt/SDCARD/System/scripts/launch.sh "$ROM" "$TARGET"
            elif [ -n "$TARGET" ] && [ -x "$TARGET" ]; then
                "$TARGET"
            fi
        fi
        # Re-launch launcher after game teardown
        continue
    elif [ "$EXIT_CODE" -eq 0 ]; then
        # Clean intentional user quit
        rm -f "$CRASH_TS_FILE"
        exit 0
    else
        # Crash occurred
        echo "$NOW" >> "$CRASH_TS_FILE"
        echo "[ERROR] LumenLauncher exited with error code $EXIT_CODE" >> "$CRASH_LOG"

        # If it ran for more than 5 seconds, clear the rapid crash history
        if [ $(( END_TIME - START_TIME )) -gt 5 ]; then
            rm -f "$CRASH_TS_FILE"
        fi
        exit "$EXIT_CODE"
    fi
done
