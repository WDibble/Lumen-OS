#!/bin/sh
# Lumen-OS Hardware Detection & Topology Initialization
# Dispatches next-hw detect to establish dynamic multi-device environment

HW_TOOL="/mnt/SDCARD/System/bin/next-hw"

if [ -x "$HW_TOOL" ]; then
    "$HW_TOOL" detect
    MODEL=$("$HW_TOOL" detect --get-model 2>/dev/null || echo "tsp")
    echo "[Lumen-OS] Hardware Profile Initialized: $MODEL"
fi

exit 0
