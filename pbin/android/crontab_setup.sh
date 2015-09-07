#!/system/bin/sh
# Setup a new crontab

# Variables
CRONTAB_SRC="${1:-$PWD}/crontab"
CRONTAB_DST="/system/etc/cron.d/crontabs/root"

# Run in a root subshell
su root <<EOF
    # setup /etc link
    if [ ! -e /etc ]; then
        mount -o remount,rw /
        ln -s /system/etc /
        mount -o remount,ro /
    fi

    # set /system rw
    mount -o remount,rw /system
    mkdir -p "$(dirname "$CRONTAB_DST")"

    # Copy crontab
    if [ -r "$CRONTAB_SRC" ]; then
        echo "[crontab] copy local crontab to $CRONTAB_DST"
        cp "$CRONTAB_SRC" "$CRONTAB_DST"
    else
        echo "[crontab] setup new empty crontab"
        echo -n > "$CRONTAB_DST"
    fi

    # reset /system ro
    mount -o remount,ro /system

    # End
    cat "$CRONTAB_DST"
    exit 0   
EOF
