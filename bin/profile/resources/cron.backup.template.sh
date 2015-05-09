#!/bin/sh

##### Cron backup (start)
ARCHIVE="/var/backups/$USER/${0%.*}"
INCLUSIONS="$HOME"
EXCLUSIONS="--exclude-vcs --one-file-system"
EXCLUSIONS="$EXCLUSIONS --exclude=tmp --exclude=temp --exclude=cache"
EXCLUSIONS="$EXCLUSIONS --exclude=.tmp --exclude=.temp --exclude=.cache"

# Delete file too old (mtime=nb days)
find "/var/backups/$USER" -name 'backup.tar*' -maxdepth 1 -mtime +28 -type f -delete

# Do the backup
ARCHIVE="${ARCHIVE}.$(date +%Y%m%d_%H%M%S).tar"
tar -cvpjf "$ARCHIVE" --one-file-system $EXCLUSIONS $INCLUSIONS | tee "${ARCHIVE}.log"
du -h -d 1 "$(dirname "$ARCHIVE")/*" . | tee -a "${ARCHIVE}.log"
##### Cron backup (end)
