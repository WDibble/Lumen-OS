#!/bin/sh
# Lumen-OS ZRAM Memory Initialization
# Target: Allwinner A133plus (1GB RAM)
# Configures 384MB compressed RAM swap with LZ4/ZSTD compression

set -e

# Only run if zram is supported by the kernel
if [ ! -b "/dev/zram0" ]; then
    modprobe zram 2>/dev/null || true
fi

if [ -b "/dev/zram0" ]; then
    # Check if already active
    if grep -q "/dev/zram0" /proc/swaps 2>/dev/null; then
        echo "[Lumen-OS] ZRAM already active."
        exit 0
    fi

    # Reset device
    swapoff /dev/zram0 2>/dev/null || true
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true

    # Prefer lz4 compression for minimum CPU overhead on A53 cores
    if grep -q "lz4" /sys/block/zram0/comp_algorithm 2>/dev/null; then
        echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || true
    fi

    # Configure 384MB disksize (384 * 1024 * 1024 bytes = 402653184)
    echo 402653184 > /sys/block/zram0/disksize 2>/dev/null || true

    # Format and activate swap with high priority
    mkswap /dev/zram0 >/dev/null 2>&1 || true
    swapon -p 100 /dev/zram0 2>/dev/null || true

    # Tune swappiness (prefer zram before dropping file cache)
    echo 80 > /proc/sys/vm/swappiness 2>/dev/null || true

    echo "[Lumen-OS] ZRAM 384MB active on /dev/zram0"
else
    echo "[Lumen-OS] ZRAM not available on this kernel."
fi
