#!/bin/sh
DBG=""
[[ ! -z "$DBG" ]] && set -x

# Beginning
/usr/bin/logger "Backup - begins at $(date)"
if [ "${1:?Please specify the source directory}" == "${2:?Please specify the target directory}" ]; then
    /usr/bin/logger "ERROR: same directory specified for both src and dst"
    exit 0
fi

# Create the mount directories and unmount if necessary
/usr/bin/logger "Backup - create mount directories"
mkdir -p /mnt/src /mnt/dst 2>/dev/null
/bin/umount -f /mnt/src /mnt/dst 2>/dev/null

# Mount
/usr/bin/logger "Backup - mount directories"
if ! /bin/mount "$1" /mnt/src; then
    /usr/bin/logger "ERROR: couldn't mount $1 -> /mnt/src"
    /bin/umount -f /mnt/src /mnt/dst 2>/dev/null
    exit 0
fi
if ! /bin/mount "$2" /mnt/dst; then
    /usr/bin/logger "ERROR: couldn't mount $2 -> /mnt/dst"
    /bin/umount -f /mnt/src /mnt/dst 2>/dev/null
    exit 0
fi

# Check the test file in each mount points
/usr/bin/logger "Backup - check mounts"
if [[ ! -z "$3" ]] && [[ ! -e /mnt/src/$3 || ! -e /mnt/dst/$3 ]]; then
    /usr/bin/logger "ERROR: couldn't find the test file $3 in the mount dir $1 & $2"
    /bin/umount -f /mnt/src /mnt/dst 2>/dev/null
    exit 0
fi

# Backup
/usr/bin/logger "Backup - starts"
${DBG} /usr/bin/rsync -av ${@:4} /mnt/src/ /mnt/dst/
/usr/bin/logger "Backup - done"

# Sync before unmount
/usr/bin/logger "Backup - sync"
/bin/sync

# unmount
/usr/bin/logger "Backup - unmount"
/bin/umount -f /mnt/src /mnt/dst

# rmdir mount directories
/usr/bin/logger "Backup - cleanup"
rmdir /mnt/src /mnt/dst 2>/dev/null

# Log end of backup
/usr/bin/logger "Backup - ends at $(date)"
[[ ! -z "$DBG" ]] && set +x
