#!/bin/sh
# Lumen-OS Graceful Application Teardown
# Performs recursive descendant process termination with active polling

TARGETS="$@"

get_descendants() {
    parent_pid="$1"
    children=$(ps -o pid,ppid 2>/dev/null | awk -v p="$parent_pid" '$2 == p {print $1}')
    for c in $children; do
        get_descendants "$c"
        echo "$c"
    done
}

is_zombie_or_dead() {
    pid="$1"
    if [ ! -d "/proc/$pid" ]; then
        return 0
    fi
    state=$(awk '/^State:/ {print $2}' "/proc/$pid/status" 2>/dev/null || true)
    if [ "$state" = "Z" ] || [ -z "$state" ]; then
        return 0
    fi
    return 1
}

if [ -z "$TARGETS" ]; then
    TARGETS=$(pgrep -f "ra64.trimui|PPSSPP|drastic|mupen64plus|flycast|DinguxCommander" 2>/dev/null || true)
fi

[ -z "$TARGETS" ] && exit 0

ALL_PIDS=""
for p in $TARGETS; do
    if [ -d "/proc/$p" ]; then
        DESC=$(get_descendants "$p")
        ALL_PIDS="$ALL_PIDS $DESC $p"
    fi
done

UNIQUE_PIDS=$(echo "$ALL_PIDS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Phase 1: Graceful SIGTERM
for pid in $UNIQUE_PIDS; do
    if ! is_zombie_or_dead "$pid"; then
        kill -TERM "$pid" 2>/dev/null || true
    fi
done

# Phase 2: Active polling wait loop (up to 30 iterations = 3.0s, 100ms interval)
ITER=0
MAX_ITER=30
while [ "$ITER" -lt "$MAX_ITER" ]; do
    STILL_ALIVE=0
    for pid in $UNIQUE_PIDS; do
        if ! is_zombie_or_dead "$pid"; then
            STILL_ALIVE=1
            break
        fi
    done

    if [ "$STILL_ALIVE" -eq 0 ]; then
        break
    fi

    if [ "$ITER" -eq 15 ]; then
        for pid in $UNIQUE_PIDS; do
            if ! is_zombie_or_dead "$pid"; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        done
    fi

    usleep 100000 2>/dev/null || sleep 0.1 2>/dev/null || sleep 1
    ITER=$(( ITER + 1 ))
done

# Phase 3: Final SIGKILL sweep if any non-zombie processes remain
for pid in $UNIQUE_PIDS; do
    if ! is_zombie_or_dead "$pid"; then
        kill -KILL "$pid" 2>/dev/null || true
    fi
done

sync
exit 0
