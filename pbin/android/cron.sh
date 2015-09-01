#!/system/bin/sh
# Setup, start and stop cron daemon

# Variables
LOGFILE="/sdcard/crond.log"
CRONTAB_SRC="/sdcard/crontab"
CRONTAB_DST="/etc/cron.d/crontabs/root"

# Run in a subshell because of the exit commands
(
    # Kill cron
    if [ "$1" = "stop" ]; then
        echo "[cron] stop cron"
        pkill crond
        exit 0
    fi
    
    # Check requirements
    echo "[cron] check requirements"
    if ! command -v crond >/dev/null 2>&1; then
        echo "[error] Cannot find crond. Abort..."
        exit 1
    fi
    
    # Root session
    echo "[cron] setup cron session"
    su root <<EOF
        # Install passwd
        echo "[cron] setup /etc/passwd"
        if [ ! -f "/etc/passwd" ] || ! grep root /etc/passwd; then
            mount -o remount,rw /etc
            echo "root::" >> /etc/passwd
            mount -o remount,ro /etc
        fi

        # Copy crontab
        echo "[cron] setup crontab"
        if [ ! -f "$CRONTAB_DST" ] || ! grep root /etc/passwd; then
            mount -o remount,rw /etc
            mkdir -p "$(dirname "$CRONTAB_DST")"
            cp "$CRONTAB_SRC" "$CRONTAB_DST"
            mount -o remount,ro /etc
        fi

        # Start crond
        echo "[cron] start cron"
        crond -d ${LOGFILE:+-l "$LOGFILE"} ${CRONTAB_DST:+-c "$CRONTAB_DST"}
EOF
    # End
    echo "[cron] done"
    exit 0   
)
