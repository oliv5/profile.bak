#!/system/bin/sh
# Setup, start and stop cron daemon

# Variables
CMD="$1"
LOGFILE="/sdcard/crond.log"
LOGLEVEL="${2:-8}"
CRONTAB_SRC="/sdcard/crontab"
CRONTAB_DST="/etc/cron.d/crontabs/root"

# Run in a subshell because of the exit commands
su root <<EOF
    # Kill cron
    if [ "$CMD" = "stop" ]; then
        echo "[cron] stop current cron"
        pkill -x crond
        exit 0
    fi
    
    # Check requirements
    echo "[cron] check requirements"
    if ! command -v crond >/dev/null 2>&1; then
        echo "[error] Cannot find crond. Abort..."
        exit 1
    fi
    
    # Install passwd
    echo "[cron] setup /etc/passwd"
    if [ ! -f "/etc/passwd" ] || ! grep root /etc/passwd >/dev/null; then
        mount -o remount,rw /etc
        echo "root:x:0:0::/system/etc/cron.d/crontabs:/system/bin/sh" >> /etc/passwd
        mount -o remount,ro /etc
    fi

    # Copy crontab
    echo "[cron] setup crontab"
    if [ ! -f "$CRONTAB_DST" ]; then
        mount -o remount,rw /etc
        mkdir -p "$(dirname "$CRONTAB_DST")"
        cp "$CRONTAB_SRC" "$CRONTAB_DST"
        mount -o remount,ro /etc
    fi
    
    # Stop previous crond
    echo "[cron] stop previous cron"
    pkill -x crond

    # Start crond
    echo "[cron] start new cron"
    crond -b ${LOGLEVEL:+-l $LOGLEVEL} ${LOGFILE:+-L "$LOGFILE"} ${CRONTAB_DST:+-c "$(dirname "$CRONTAB_DST")"}
    pgrep -l crond

    # End
    echo "[cron] done"
    exit 0   
EOF
