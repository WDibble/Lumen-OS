#!/bin/sh
# Lumen-OS Fast Game Switcher
# Intercepted by triggerhappy (SELECT + MENU or SELECT + START)
# Enforces Single-Process Lifespan on 1GB RAM A133plus SoC.

RA_PID=$(pgrep -f "ra64.trimui" 2>/dev/null || true)
if [ -n "$RA_PID" ]; then
    # In-game switcher: serialize state and cleanly exit to Activities
    printf 'SAVE_STATE\n' | nc -u -w1 127.0.0.1 55355 2>/dev/null || true
    sleep 1.2
    kill -TERM "$RA_PID" 2>/dev/null || true
    sleep 0.5
    /mnt/SDCARD/System/bin/activities gui
    exit 0
fi

MAINUI_PID=$(pidof MainUI 2>/dev/null || true)
if [ -n "$MAINUI_PID" ]; then
    pkill -STOP runtrimui.sh 2>/dev/null || true
    kill -9 "$MAINUI_PID" 2>/dev/null || true
    /mnt/SDCARD/System/bin/activities gui
    pkill -CONT runtrimui.sh 2>/dev/null || true
    exit 0
fi

# Fallback: launch Activities directly
/mnt/SDCARD/System/bin/activities gui
