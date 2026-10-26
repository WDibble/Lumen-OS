#!/bin/sh
# Lumen-OS Out-Of-Box Experience (OOBE) & First Boot Sentinel
# Fast-path: < 2ms execution when already initialized
[ -f "/mnt/SDCARD/.lumen_initialized" ] && exit 0

SD_ROOT="/mnt/SDCARD"
VERSION="v1.0.0"

echo "[OOBE] Initializing Lumen-OS $VERSION cold setup..."

# 1. Directory Tree Guarantees
mkdir -p "$SD_ROOT/BIOS/dc" \
         "$SD_ROOT/BIOS/neogeo" \
         "$SD_ROOT/Roms" \
         "$SD_ROOT/Saves/RetroArch" \
         "$SD_ROOT/Saves/Standalones" \
         "$SD_ROOT/Screenshots" \
         "$SD_ROOT/Themes" \
         "$SD_ROOT/System/bin" \
         "$SD_ROOT/System/etc/dropbear" \
         "$SD_ROOT/System/logs" \
         "$SD_ROOT/System/res" \
         "$SD_ROOT/System/scripts" 2>/dev/null || true

# 2. Cryptographic Dropbear Host Key Generation
DROPBEAR_DIR="$SD_ROOT/System/etc/dropbear"
KEYGEN_BIN=""
if [ -x "$SD_ROOT/System/bin/dropbearkey" ]; then
    KEYGEN_BIN="$SD_ROOT/System/bin/dropbearkey"
elif command -v dropbearkey >/dev/null 2>&1; then
    KEYGEN_BIN="dropbearkey"
fi

if [ -n "$KEYGEN_BIN" ]; then
    if [ ! -f "$DROPBEAR_DIR/dropbear_ed25519_host_key" ]; then
        echo "[OOBE] Generating persistent Dropbear ED25519 host key..."
        "$KEYGEN_BIN" -t ed25519 -f "$DROPBEAR_DIR/dropbear_ed25519_host_key" 2>/dev/null || true
    fi
    if [ ! -f "$DROPBEAR_DIR/dropbear_rsa_host_key" ]; then
        echo "[OOBE] Generating persistent Dropbear RSA host key..."
        "$KEYGEN_BIN" -t rsa -s 2048 -f "$DROPBEAR_DIR/dropbear_rsa_host_key" 2>/dev/null || true
    fi
fi

# 3. Visual & Acoustic Welcome Experience
HW_TOOL="$SD_ROOT/System/bin/next-hw"
if [ -x "$HW_TOOL" ]; then
    # Cyan pulse welcome
    "$HW_TOOL" led --hex 38BDF8 --cycles 2 2>/dev/null || true
fi

# 3.5 Auto-apply Lumen Theme to MainUI
if [ -x "/usr/trimui/bin/systemval" ]; then
    CURRENT_THEME=$(/usr/trimui/bin/systemval theme 2>/dev/null || true)
    if [ "$CURRENT_THEME" != "/mnt/SDCARD/Themes/Lumen" ]; then
        echo "[OOBE] Activating Lumen theme in MainUI..."
        /usr/trimui/bin/systemval theme "/mnt/SDCARD/Themes/Lumen" 2>/dev/null || true
    fi
fi

# 4. Atomic Initialization Commit
TMP_FLAG="$SD_ROOT/.lumen_initialized.tmp"
cat <<EOF > "$TMP_FLAG"
VERSION=$VERSION
INITIALIZED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "1970-01-01T00:00:00Z")
SOC=Allwinner A133plus
DISPLAY=1280x720
EOF
sync
mv -f "$TMP_FLAG" "$SD_ROOT/.lumen_initialized" 2>/dev/null || true
sync

echo "[OOBE] Lumen-OS initialization complete."
exit 0
