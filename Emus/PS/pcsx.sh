#!/bin/sh
# Sony PlayStation High-Resolution Mode Launcher (PCSX-ReARMed)
# Configures neon enhancement options in retroarch-core-options.cfg

ARG1="$1"
ARG2="$2"

if [ -f "$ARG1" ]; then
    ROM_PATH="$ARG1"
    MODE="$ARG2"
elif [ -f "$ARG2" ]; then
    ROM_PATH="$ARG2"
    MODE="$ARG1"
else
    ROM_PATH="$ARG1"
    MODE="$ARG2"
fi

RA_DIR="/mnt/SDCARD/RetroArch"
CORE_OPTS="$RA_DIR/.retroarch/retroarch-core-options.cfg"
mkdir -p "$RA_DIR/.retroarch"
[ -f "$CORE_OPTS" ] || touch "$CORE_OPTS"

set_core_opt() {
    key="$1"
    val="$2"
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$CORE_OPTS" 2>/dev/null; then
        sed -i "s|^[[:space:]]*$key[[:space:]]*=.*|$key = \"$val\"|" "$CORE_OPTS"
    else
        echo "$key = \"$val\"" >> "$CORE_OPTS"
    fi
}

case "$MODE" in
    hires)
        set_core_opt "pcsx_rearmed_neon_enhancement_enable" "enabled"
        set_core_opt "pcsx_rearmed_neon_enhancement_no_main" "disabled"
        ;;
    hires_speedhack)
        set_core_opt "pcsx_rearmed_neon_enhancement_enable" "enabled"
        set_core_opt "pcsx_rearmed_neon_enhancement_no_main" "enabled"
        ;;
    *)
        set_core_opt "pcsx_rearmed_neon_enhancement_enable" "disabled"
        set_core_opt "pcsx_rearmed_neon_enhancement_no_main" "disabled"
        ;;
esac

DISPATCHER="/mnt/SDCARD/System/scripts/launch.sh"
if [ -f "$DISPATCHER" ]; then
    exec sh "$DISPATCHER" "$ROM_PATH" "pcsx_rearmed_libretro.so"
else
    CORE="$RA_DIR/.retroarch/cores/pcsx_rearmed_libretro.so"
    cd "$RA_DIR" || exit 1
    HOME="$RA_DIR" exec "$RA_DIR/ra64.trimui" -v -L "$CORE" "$ROM_PATH"
fi
