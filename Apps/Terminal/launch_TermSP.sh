#!/bin/sh
# Lumen-OS TermSP Launcher

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

chmod +x ./TermSP 2>/dev/null || true

export TERM=xterm-256color
export HOME="/mnt/SDCARD"
export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/scripts:${PATH:-/bin:/usr/bin:/usr/trimui/bin}"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:-}"

FLAGS=""
[ $# -eq 0 ] && FLAGS="-k"

exec ./TermSP $FLAGS "$@"
