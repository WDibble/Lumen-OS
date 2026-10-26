#!/bin/sh
# Sony PlayStation Portable Launcher Wrapper (PPSSPP 1.17.1)
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
EMU_DIR="/mnt/SDCARD/Emus/PSP/PPSSPP_1.17.1"
CONFIG_FILE="$EMU_DIR/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"

mkdir -p "$EMU_DIR/.config/ppsspp/PSP/SYSTEM"

# Sanitize CRLF and remediate mute bug
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's/\r$//' "$CONFIG_FILE" 2>/dev/null || true
    if grep -q '^\[Sound\]' "$CONFIG_FILE"; then
        sed -i '/^\[Sound\]$/,/^\[/ s/GlobalVolume = .*/GlobalVolume = 10/' "$CONFIG_FILE" 2>/dev/null || true
        sed -i '/^\[Sound\]$/,/^\[/ s/AudioMuted = .*/AudioMuted = False/' "$CONFIG_FILE" 2>/dev/null || true
    fi
    if grep -q '^\[Audio\]' "$CONFIG_FILE"; then
        sed -i '/^\[Audio\]$/,/^\[/ s/GlobalVolume = .*/GlobalVolume = 10/' "$CONFIG_FILE" 2>/dev/null || true
        sed -i '/^\[Audio\]$/,/^\[/ s/AudioMuted = .*/AudioMuted = False/' "$CONFIG_FILE" 2>/dev/null || true
    fi
fi

if [ "$MODE" = "vulkan" ]; then
    # Set backend to Vulkan
    [ -f "$CONFIG_FILE" ] && sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 3/' "$CONFIG_FILE" 2>/dev/null || true
    EXEC="$EMU_DIR/PPSSPPSDL_vulkan"
else
    # Default: OpenGL ES
    [ -f "$CONFIG_FILE" ] && sed -i '/^\[Graphics\]$/,/^\[/ s/GraphicsBackend = .*/GraphicsBackend = 0/' "$CONFIG_FILE" 2>/dev/null || true
    EXEC="$EMU_DIR/PPSSPPSDL_gl"
fi

if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "$EXEC"
else
    cd "$EMU_DIR"
    HOME="$EMU_DIR" exec "$EXEC" "$ROM_PATH"
fi
