#!/bin/sh

##### Cron backup (start)
[ -z "$ENV_PROFILE" ] && . "$HOME/.profile"
DIR="/var/backups/$USER"
INCLUSIONS="$HOME"
EXCLUSIONS="--exclude-vcs --one-file-system"
EXCLUSIONS="$EXCLUSIONS --exclude=tmp --exclude=temp --exclude=cache"
EXCLUSIONS="$EXCLUSIONS --exclude=.tmp --exclude=.temp --exclude=.cache"

# Set archive variable
ARCHIVE="${0##*/}"
ARCHIVE="${ARCHIVE%.*}.$(date +%Y%m%d_%H%M%S)"

# Make directory
mkdir -p "$DIR"
chown $USER:$USER -R "$DIR"

# Delete file too old (mtime=nb days)
find "$DIR" -maxdepth 1 -name 'backup.tar*' -mtime +27 -type f -delete

# Do the backup
tar -cvpjf "$DIR/${ARCHIVE}.tar.bz" --one-file-system $EXCLUSIONS $INCLUSIONS | tee "$DIR/${ARCHIVE}.log"
du -h -d 1 "$DIR/*" . | tee -a "$DIR/${ARCHIVE}.log"
##### Cron backup (end)
