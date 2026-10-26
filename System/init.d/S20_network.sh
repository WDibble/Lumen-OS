#!/bin/sh
# Lumen-OS Init Service: Network & Remote Daemons (Dropbear, Samba, Avahi)
# Invariant: Zero NAND Mutation. All locks, state, and runtime sockets in /tmp/lumen/

ACTION="${1:-start}"
CONFIG_FILE="/mnt/SDCARD/System/etc/config.json"
RUN_DIR="/tmp/lumen/run"
SAMBA_DIR="/tmp/lumen/samba"
DROPBEAR_KEYS_DIR="/mnt/SDCARD/System/etc/dropbear"

mkdir -p "$RUN_DIR" "$SAMBA_DIR/locks" "$SAMBA_DIR/state" "$SAMBA_DIR/cache" "$SAMBA_DIR/private" "$DROPBEAR_KEYS_DIR"

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib/samba:/mnt/SDCARD/System/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="/mnt/SDCARD/System/bin:$PATH"

read_config_bool() {
    KEY="$1"
    DEFAULT="$2"
    if [ -f "$CONFIG_FILE" ]; then
        if command -v jq >/dev/null 2>&1; then
            VAL=$(jq -r "$KEY // $DEFAULT" "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT")
            [ "$VAL" = "true" ] && echo 1 && return
            [ "$VAL" = "1" ] && echo 1 && return
            echo 0 && return
        elif grep -Eq "\"$3\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE" 2>/dev/null; then
            echo 1 && return
        fi
    fi
    echo "$DEFAULT"
}

case "$ACTION" in
    start)
        SSH_ENABLED=$(read_config_bool '.services.ssh' 1 'ssh')
        SAMBA_ENABLED=$(read_config_bool '.services.samba' 0 'samba')
        AVAHI_ENABLED=$(read_config_bool '.services.avahi' 1 'avahi')

        # 1. Dropbear SSH Daemon
        if [ "$SSH_ENABLED" = "1" ]; then
            DROPBEAR_PID="$RUN_DIR/dropbear.pid"
            if [ -f "$DROPBEAR_PID" ] && kill -0 "$(cat "$DROPBEAR_PID")" 2>/dev/null; then
                echo "[S20_network] Dropbear SSH already running (PID $(cat "$DROPBEAR_PID"))."
            else
                RSA_KEY="$DROPBEAR_KEYS_DIR/dropbear_rsa_host_key"
                if [ ! -f "$RSA_KEY" ]; then
                    echo "[S20_network] Generating persistent SSH host key on SD card..."
                    if [ -x "/mnt/SDCARD/System/bin/dropbearkey" ]; then
                        /mnt/SDCARD/System/bin/dropbearkey -t rsa -f "$RSA_KEY" >/dev/null 2>&1 || true
                    fi
                fi

                DROPBEAR_BIN="/mnt/SDCARD/System/bin/dropbear"
                [ ! -x "$DROPBEAR_BIN" ] && DROPBEAR_BIN="/usr/sbin/dropbear"

                if [ -x "$DROPBEAR_BIN" ]; then
                    KEY_ARG=""
                    [ -f "$RSA_KEY" ] && KEY_ARG="-r $RSA_KEY"
                    "$DROPBEAR_BIN" $KEY_ARG -P "$DROPBEAR_PID" -p 22 -B 2>/dev/null || \
                    "$DROPBEAR_BIN" $KEY_ARG -p 22 -B 2>/dev/null || true
                    echo "[S20_network] Started Dropbear SSH daemon."
                fi
            fi
        fi

        # 2. Samba Daemon (SMBv2/v3 file sharing)
        if [ "$SAMBA_ENABLED" = "1" ]; then
            SMB_PID="$RUN_DIR/smbd.pid"
            if [ -f "$SMB_PID" ] && kill -0 "$(cat "$SMB_PID")" 2>/dev/null; then
                echo "[S20_network] Samba already running (PID $(cat "$SMB_PID"))."
            else
                SMB_CONF="/mnt/SDCARD/System/etc/samba/smb.conf"
                SMBD_BIN="/mnt/SDCARD/System/bin/smbd"
                [ ! -x "$SMBD_BIN" ] && SMBD_BIN="smbd"

                if [ -f "$SMB_CONF" ] && command -v "$SMBD_BIN" >/dev/null 2>&1; then
                    "$SMBD_BIN" -s "$SMB_CONF" -D
                    echo "[S20_network] Started Samba daemon (sandboxed to MicroSD)."
                fi
            fi
        fi

        # 3. Avahi mDNS Daemon (trimui.local)
        if [ "$AVAHI_ENABLED" = "1" ]; then
            AVAHI_CONF="/mnt/SDCARD/System/etc/avahi/avahi-daemon.conf"
            AVAHI_BIN="/usr/sbin/avahi-daemon"
            if [ -x "$AVAHI_BIN" ] && [ -f "$AVAHI_CONF" ]; then
                if ! pgrep -x avahi-daemon >/dev/null 2>&1; then
                    "$AVAHI_BIN" --file="$AVAHI_CONF" --no-drop-root -D >/dev/null 2>&1 || true
                    echo "[S20_network] Started Avahi mDNS daemon (trimui.local)."
                fi
            fi
        fi
        ;;

    stop)
        echo "[S20_network] Stopping network daemons..."
        # Stop Dropbear
        if [ -f "$RUN_DIR/dropbear.pid" ]; then
            kill "$(cat "$RUN_DIR/dropbear.pid")" 2>/dev/null || true
            rm -f "$RUN_DIR/dropbear.pid"
        fi
        killall dropbear 2>/dev/null || true

        # Stop Samba
        if [ -f "$RUN_DIR/smbd.pid" ]; then
            kill "$(cat "$RUN_DIR/smbd.pid")" 2>/dev/null || true
            rm -f "$RUN_DIR/smbd.pid"
        fi
        killall smbd 2>/dev/null || true
        killall nmbd 2>/dev/null || true

        # Stop Avahi
        killall avahi-daemon 2>/dev/null || true
        echo "[S20_network] Network daemons stopped."
        ;;

    status)
        pgrep -x dropbear >/dev/null && echo "Dropbear SSH: running" || echo "Dropbear SSH: stopped"
        pgrep -x smbd >/dev/null && echo "Samba SMB: running" || echo "Samba SMB: stopped"
        pgrep -x avahi-daemon >/dev/null && echo "Avahi mDNS: running" || echo "Avahi mDNS: stopped"
        ;;

    restart)
        $0 stop
        sleep 0.5
        $0 start
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
