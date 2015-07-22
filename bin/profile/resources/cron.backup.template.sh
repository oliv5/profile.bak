#!/bin/sh

##### Cron backup (start)
[ -z "$ENV_PROFILE" ] && . "$HOME/.profile"
DIR="/var/backups/$USER"
INCLUSIONS="$HOME"
EXCLUSIONS="--exclude-vcs --one-file-system"
EXCLUSIONS="$EXCLUSIONS --exclude=tmp --exclude=temp --exclude=cache"
EXCLUSIONS="$EXCLUSIONS --exclude=.tmp --exclude=.temp --exclude=.cache"

# Set archive variable
PREAMBLE="${0##*/}"
PREAMBLE="${PREAMBLE%.*}.$(uname -n)"
ARCHIVE="${PREAMBLE}.$(date +%Y%m%d_%H%M%S)"

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
    find "$DIR" -maxdepth 1 -name "${PREAMBLE}"'*' -mtime +27 -type f -print -delete
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
