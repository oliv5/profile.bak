#!/system/bin/sh
# Setup a new system

# Prerequisite
if [ -f "./crontab" ]; then
    # Setup cron
    . ../crontab_setup.sh
    . ../initd_setup.sh -f ../cron.sh
    . ../cron.sh
else
    echo "crontab: file not found. Abort..."
fi
