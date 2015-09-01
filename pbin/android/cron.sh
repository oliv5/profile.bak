#!/system/bin/sh
# Setup, start and stop cron daemon

# Variables
CMD="$1"
LOGFILE="/sdcard/crond.log"
LOGLEVEL="${2:-8}"
CRONTAB="/etc/cron.d/crontabs/root"

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
    
    # Stop previous crond
    echo "[cron] stop previous cron"
    pkill -x crond

    # Start crond
    if [ -r "$CRONTAB" ]; then
        echo "[cron] start new cron"
        crond -b ${LOGLEVEL:+-l $LOGLEVEL} ${LOGFILE:+-L "$LOGFILE"} ${CRONTAB:+-c "$(dirname "$CRONTAB")"}
    else
        echo "[warning] do not start cron: no crontab file present."
    fi
    pgrep -l crond

    # End
    exit 0   
EOF
