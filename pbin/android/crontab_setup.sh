#!/system/bin/sh
# Setup a new crontab

# Variables
CRONTAB="/etc/cron.d/crontabs/root"

# Run in a root subshell
su root <<EOF
    # set /etc rw
    mount -o remount,rw /etc
    mkdir -p "$(dirname "$CRONTAB")"

    # Copy crontab
    if [ -r "./crontab" ]; then
        echo "[crontab] copy local crontab to $CRONTAB"
        cp "./crontab" "$CRONTAB"
    else
        echo "[crontab] setup new empty crontab"
        echo -n > "$CRONTAB"
    fi

    # reset /etc ro
    mount -o remount,ro /etc

    # End
    exit 0   
EOF
