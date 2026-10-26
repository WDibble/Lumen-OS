#!/bin/sh
# Nintendo 64 Launcher Wrapper (Mupen64Plus Standalone / Libretro)
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
EMU_DIR="/mnt/SDCARD/Emus/N64/mupen64plus"
CFG="$EMU_DIR/mupen64plus.cfg"

export HOME="$EMU_DIR"
export XDG_CONFIG_HOME="$EMU_DIR"
export XDG_DATA_HOME="$EMU_DIR"
export LD_LIBRARY_PATH="$EMU_DIR:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [ "$MODE" = "rice" ]; then
    [ -f "$CFG" ] && sed -i 's/VideoPlugin = .*/VideoPlugin = "mupen64plus-video-rice.so"/' "$CFG" 2>/dev/null || true
else
    # Default: Glide64mk2 accurate plugin
    [ -f "$CFG" ] && sed -i 's/VideoPlugin = .*/VideoPlugin = "mupen64plus-video-glide64mk2.so"/' "$CFG" 2>/dev/null || true
fi

EXEC="$EMU_DIR/mupen64plus"

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "$EXEC"
else
    cd "$EMU_DIR"
    exec "$EXEC" "$ROM_PATH"
fi
