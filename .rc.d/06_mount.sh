#!/bin/sh

# Mount cleaner
# Keep a number of mounts matching input regex
mount_cleaner() {
  local SEARCH="${1:?No mount specified...}"
  local WANTED="${2:-0}"
  local COUNT="$(mount | grep -e "$SEARCH" | wc -l)"
  sudo root "
    mount | grep -e '$SEARCH' | cut -d ' ' -f 3 | 
      while IFS= read -r MOUNT && [ $COUNT -gt $WANTED ]; do
        COUNT=$((COUNT - 1))
        umount '$MOUNT'
      done
  "
}

# Mount ecryptfs
mount_ecryptfs() {
  local SRC="${1:?Missing source directory...}"
  local DST="${2:?Missing dest directory...}"
  local KEY1="${3:?Missing content key...}"
  local KEY2="${4:-$KEY1}"
  local CIPHER="${5:-aes}"
  local KEYLEN="${6:-32}"
  shift $(min 6 $#)
  local OPT="key=passphrase,ecryptfs_enable_filename_crypto=yes,no_sig_cache=yes,ecryptfs_passthrough=no${@:+,$@}"
  OPT="ecryptfs_cipher=$CIPHER,ecryptfs_key_bytes=$KEYLEN,ecryptfs_sig=$KEY1,ecryptfs_fnek_sig=$KEY2,ecryptfs_unlink_sigs${OPT:+,$OPT}"
  if [ "$SRC" = "$DST" ]; then
    echo "ERROR: same source and destination directories."
    return 1
  fi
  chmod 500 "$SRC"
  sudo ecryptfs-add-passphrase --fnek
  sudo mount -i -t ecryptfs -o "$OPT" "$SRC" "$DST"
  chmod 700 "$DST"
}

# Mount/umount ecryptfs private directory
mount_private() {
  local SRC="${1:-$HOME/.private}"
  local DST="${2:-$HOME/private}"
  local SIG="${3:-$HOME/.ecryptfs/private.sig}"
  local KEY="$(cat "$SIG" 2>/dev/null)"
  mkdir -p "$DST"
	mount_ecryptfs "$SRC" "$DST" "$KEY"
}
umount_private() {
  local DST="$HOME/private"
	if mountpoint "$DST" 2>&1 >/dev/null; then
		sudo umount "$DST"
	fi
}

# Mount encfs
mount_encfs() {
  local SRC="${1:?Missing source directory...}"
  local DST="${2:?Missing dest directory...}"
  local KEY="${3:?Missing encfs key...}"
  local PASSFILE="${4}"
  shift $(min 4 $#)
  ENCFS6_CONFIG="$(readlink -f "$KEY")" sudo -E encfs -o nonempty ${PASSFILE:+--extpass='cat "$PASSFILE"'} "$@" "$SRC" "$DST"
}

# Mount iso
mount_iso() {
  sudo mount -o loop -t iso9660 "$@"
}

# Mount dd img
mount_img() {
  local SRC="${1:?No image specified...}"
  local OFFSET="${2:?No byte offset specified. See fdisk -l '$SRC'}"
  local DST="${3:-/mnt}"
  sudo mkdir -p "$DST"
  sudo mount -o ro,loop,offset=$OFFSET "$SRC" "$DST"
}
umount_img() {
  local DST="${1:-/mnt}"
  sudo umount "$DST"
  [ "$(readlink -f "$DST")" != "/mnt" ] && sudo rmdir "$DST"
}

# Unmount nfs
alias umountall_nfs='umount -a -t nfs'
umount_nfs() {
  local MOUNTPOINT="${1:?NFS mount point not specified...}"
  local ITF="${2:-eth0}"
  local IP="${3:-192.168.0.1}"
  local TMPFS="${4:-nfstmp}"
  #local TMPFS="${4:-fakenfs}"
  sudo sh -c "
    sh -c 'echo 0 > /proc/sys/kernel/hung_task_timeout_secs'
    ifconfig $ITF:$TMPFS $IP netmask 255.255.255.255
    umount -f -l \"$MOUNTPOINT\"
    ifconfig $ITF:$TMPFS down
  "
}

# Toggle autofs
autofs_toggle() {
  sudo service autofs stop
  for MOUNT; do
    sudo umount -l "$MOUNT"
  done
  sleep 5s
  sudo service autofs start   
}

# Check logged on users have a local home
check_nfs() {
	for LOGGED_USERS in $(who | awk '{print $1}' | sort | uniq); do
		if ! grep $LOGGED_USERS /etc/exports >/dev/null; then
			echo "WARNING: user $LOGGED_USERS is logged in using a remote home..."
		fi
	done
}

# Mount sshfs
alias umount_sshfs='fusermount -u'
alias mount_sshfs='sshfs -o cache=yes -o kernel_cache -o compression=no -o large_read'
alias mount_sshfs_fast='sshfs -o cache=yes -o kernel_cache -o compression=no -o large_read -o Ciphers=arcfour'
