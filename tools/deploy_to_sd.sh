#!/bin/sh
# Lumen-OS SD Card Deployment Utility
# Safely synchronizes Lumen-OS to a mounted MicroSD card on macOS / Linux

set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT"

TARGET_MOUNT="$1"

# Auto-detect mounted SD card on macOS if not specified
if [ -z "$TARGET_MOUNT" ]; then
    for candidate in /Volumes/TRIMUI /Volumes/SDCARD /Volumes/LUMEN /Volumes/NO\ NAME /Volumes/Untitled; do
        if [ -d "$candidate" ]; then
            TARGET_MOUNT="$candidate"
            break
        fi
    done
fi

if [ -z "$TARGET_MOUNT" ] || [ ! -d "$TARGET_MOUNT" ]; then
    echo "Usage: $0 /path/to/mounted/sdcard"
    echo "Available volumes in /Volumes:"
    ls -1 /Volumes 2>/dev/null || true
    exit 1
fi

echo "=================================================="
echo "    Lumen-OS SD Card Deployment Utility      "
echo "    Source: $REPO_ROOT                            "
echo "    Target: $TARGET_MOUNT                         "
echo "=================================================="

# Safety confirmation
printf "Proceed with deployment to '%s'? (y/N): " "$TARGET_MOUNT"
read -r CONFIRM
case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) echo "Deployment aborted by user."; exit 0 ;;
esac

echo "[1/4] Cleansing macOS metadata from source..."
export COPYFILE_DISABLE=1
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "._*" -delete 2>/dev/null || true

echo "[2/4] Synchronizing system files via rsync..."
# Sync directories preserving existing user ROMs and Saves
rsync -avh --progress \
    --exclude='Roms/' \
    --exclude='Saves/' \
    --exclude='Screenshots/' \
    --exclude='.lumen_initialized*' \
    --exclude='.git*' \
    --exclude='tests/' \
    --exclude='tools/' \
    --exclude='dist/' \
    Apps BIOS Emus RetroArch System Themes Backgrounds Icons trimui \
    "$TARGET_MOUNT/"

# Initialize Roms directory structure without overwriting existing files
if [ -d "Roms" ]; then
    echo "[3/4] Ensuring ROM directory scaffold on target..."
    rsync -av --ignore-existing Roms/ "$TARGET_MOUNT/Roms/"
fi

# Clean dot files on target
if command -v dot_clean >/dev/null 2>&1; then
    echo "[4/4] Sanitizing FAT32 metadata on target volume..."
    dot_clean -m "$TARGET_MOUNT" 2>/dev/null || true
fi

sync

echo "=================================================="
echo " DEPLOYMENT COMPLETE"
echo " Safe to eject SD card and insert into TrimUI Smart Pro."
echo "=================================================="
