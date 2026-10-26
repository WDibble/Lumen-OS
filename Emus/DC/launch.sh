#!/bin/sh
# Sega Dreamcast Launcher Wrapper (Flycast Standalone v2.4 / Libretro)
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
EMU_DIR="/mnt/SDCARD/Emus/DC/flycast_v2.4"
LIB_DIR="/mnt/SDCARD/Emus/DC/flycast_v1.0/lib"
BIOS_DIR="/mnt/SDCARD/BIOS/dc"

mkdir -p "$BIOS_DIR/flycast" "$EMU_DIR/config"

export HOME="$EMU_DIR"
export FLYCAST_BIOS_DIR="$BIOS_DIR"
export FLYCAST_DATA_DIR="$BIOS_DIR/flycast"
export FLYCAST_CONFIG_DIR="$EMU_DIR/config"
export XDG_DATA_HOME="$BIOS_DIR/flycast"
export XDG_CONFIG_HOME="$EMU_DIR/config"
export LD_LIBRARY_PATH="$LIB_DIR:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

EXEC="$EMU_DIR/flycast"

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "$EXEC"
else
    cd "$EMU_DIR"
    exec "$EXEC" "$ROM_PATH"
fi
