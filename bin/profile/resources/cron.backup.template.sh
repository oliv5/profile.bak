#!/bin/sh

##### Cron backup (start)
[ -z "$ENV_PROFILE" ] && . "$HOME/.profile"
DIR="/var/backups/$USER"
INCLUSIONS="$HOME"
EXCLUSIONS="--exclude-vcs --one-file-system"
EXCLUSIONS="$EXCLUSIONS --exclude=tmp --exclude=temp --exclude=cache"
EXCLUSIONS="$EXCLUSIONS --exclude=.tmp --exclude=.temp --exclude=.cache"

# Set archive variable
BASENAME="${0##*/}"
BASENAME="${BASENAME%.*}.$(uname -n)"
ARCHIVE="${BASENAME}.$(date +%Y%m%d_%H%M%S)"

# Main script redirection
{
    # Startup
    date

    # Make directory
    echo "[$0] create directories..."
    mkdir -p "$DIR"
    chown $USER:$USER -R "$DIR"
    echo

    # Delete file too old (mtime=nb days)
    echo "[$0] delete old files..."
    if [ $(find "$DIR" -maxdepth 1 -type f -name "${BASENAME}"'*' -not -mtime +27 -print | wc -l) -gt 0 ]; then
      find "$DIR" -maxdepth 1 -type f -name "${BASENAME}"'*' -mtime +27 -print -delete
    fi
    echo

    # Do the backup
    echo "[$0] backup files..."
    tar -cvpjf "$DIR/${ARCHIVE}.tar.bz" --one-file-system $EXCLUSIONS $INCLUSIONS
    echo

    # Display snapshot
    echo "[$0] Show the results..."
    du -h -d 1 "$DIR" -a
    echo
    
    # End
    date

} 2>&1 | tee -a "$DIR/${ARCHIVE}.log"
##### Cron backup (end)
