#!/bin/sh
# Lumen-OS Init Service: Filesystem & Storage Protection

ACTION="${1:-start}"

case "$ACTION" in
    start)
        # Create tmpfs runtime paths
        mkdir -p /tmp/lumen/state \
                 /tmp/lumen/lock \
                 /tmp/lumen/log \
                 /tmp/lumen/osd \
                 /tmp/lumen/run \
                 /tmp/lumen/samba \
                 /tmp/lumen/xdg

        # Ensure user data directories exist on SD card
        USERDATA_DIR="/mnt/SDCARD/System/userdata"
        mkdir -p "$USERDATA_DIR/trimui_dir"

        # Safe bind-mount: protect internal NAND UDISK from write wear
        # Use sentinel file check to detect if bind-mount is already active
        SENTINEL="$USERDATA_DIR/.lumen_bind"
        touch "$SENTINEL"
        if [ -d "/mnt/UDISK" ] && [ -d "$USERDATA_DIR" ]; then
            if [ ! -f "/mnt/UDISK/.lumen_bind" ]; then
                mount -o bind "$USERDATA_DIR" /mnt/UDISK
                echo "[S01_filesystem] Bind-mounted $USERDATA_DIR -> /mnt/UDISK (NAND write-protection active)"
            else
                echo "[S01_filesystem] /mnt/UDISK already bind-mounted."
            fi
        fi
        ;;
    stop)
        if [ -f "/mnt/UDISK/.lumen_bind" ]; then
            umount -l /mnt/UDISK 2>/dev/null || true
            echo "[S01_filesystem] Unmounted /mnt/UDISK"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
