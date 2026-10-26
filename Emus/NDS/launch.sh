#!/bin/sh
# Nintendo DS Launcher Wrapper (Drastic / Libretro)
if [ -n "$2" ]; then
    if [ -f "$1" ]; then
        ROM_PATH="$1"
        MODE="$2"
    else
        MODE="$1"
        ROM_PATH="$2"
    fi
else
    ROM_PATH="$1"
    MODE=""
fi

DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"

# If an alternate Libretro core was selected via launchlist
if [ "${MODE%.so}" != "$MODE" ]; then
    if [ -f "$DISPATCHER" ]; then
        exec sh "$DISPATCHER" "$ROM_PATH" "$MODE"
    fi
fi
EMU_DIR="/mnt/SDCARD/Emus/NDS/drastic"

export HOME="$EMU_DIR"
export LD_LIBRARY_PATH="$EMU_DIR/lib:$EMU_DIR/libs:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [ "$MODE" = "nearest" ]; then
    EXEC="$EMU_DIR/drastic_2.5.2.2_nearest"
elif [ "$MODE" = "advanced" ]; then
    EXEC="$EMU_DIR/drastic"
else
    # Default: bilinear scaling
    EXEC="$EMU_DIR/drastic_2.5.2.2"
fi

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "$EXEC"
else
    cd "$EMU_DIR"
    exec "$EXEC" "$ROM_PATH"
fi
