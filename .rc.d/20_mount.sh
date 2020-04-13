#!/bin/sh

# Aliases
alias remount_rw='sudo mount -o remount,rw'
alias remount_ro='sudo mount -o remount,ro'

# Mount checker
_mounted_one() {
  local PATTERN="${1:?No pattern specified...}"
  local MOUNT="$(mount)"
  shift 1
  for M; do
    echo "$MOUNT" | grep "on $M " | grep -q -e "$PATTERN" && return 0 # one mounted
  done
  return 1 # none mounted
}
_mounted_all() {
  local PATTERN="${1:?No pattern specified...}"
  local MOUNT="$(mount)"
  shift 1
  for M; do
    echo "$MOUNT" | grep "on $M " | grep -q -e "$PATTERN" || return 1 # not all mounted
  done
  return 0 # all mounted
}
mounted() { _mounted_all " " "$@"; }
mounted_rw() { _mounted_one "[(\s,]rw[\s,)]" "$@"; }
mounted_ro() { _mounted_one "[(\s,]ro[\s,)]" "$@"; }
mounted_net() { _mounted_one "type \(cifs\|nfs\|fuse.sshfs\)" "$@"; }
mounted_nfs() { _mounted_one "type nfs" "$@"; }
mounted_cifs() { _mounted_one "type cifs" "$@"; }
mounted_sshfs() { _mounted_one "type fuse.sshfs" "$@"; }
mounted_autofs() { _mounted_one "type autofs" "$@"; }

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

#####################################
# https://wiki.archlinux.org/index.php/ECryptfs#Encrypting_a_data_directory
# https://wiki.archlinux.org/index.php/ECryptfs#Manual_setup

# Raw mount ecryptfs
mount_ecryptfs() {
  local SRC="${1:?Missing source directory...}"
  local DST="${2:?Missing dest directory...}"
  local KEY1="${3:?Missing content key...}"
  local KEY2="${4:-$KEY1}"
  local CIPHER="${5:-aes}"
  local KEYLEN="${6:-32}"
  shift $(min 6 $#)
  local OPT="$@"
  local VERSION="$(ecryptfsd -V | awk '{print $3;exit}' | bc)"
  if [ $VERSION -lt 111 ]; then
    local OPT="key=passphrase,ecryptfs_enable_filename_crypto=yes,no_sig_cache=yes,ecryptfs_passthrough=no${@:+,$@}"
  fi
  OPT="ecryptfs_cipher=$CIPHER,ecryptfs_key_bytes=$KEYLEN,ecryptfs_sig=$KEY1,ecryptfs_fnek_sig=$KEY2,ecryptfs_unlink_sigs${OPT:+,$OPT}"
  if [ "$SRC" = "$DST" ]; then
    echo "ERROR: same source and destination directories."
    return 1
  fi
  chmod 500 "$SRC"
  if [ $VERSION -lt 111 ]; then
    sudo ecryptfs-add-passphrase --fnek
    sudo mount -i -t ecryptfs -o "$OPT" "$SRC" "$DST"
  else
    sudo mount -t ecryptfs -o "$OPT" "$SRC" "$DST"
  fi
  chmod 700 "$DST"
}
umount_ecryptfs() {
  sudo umount -f "${1:?Missing mounted directory...}" ||
    sudo umount -l "${1:?Missing mounted directory...}"
  sudo keyctl clear @u
}

# Private mount wrappers
mount_private_ecryptfs() {
  local SRC="${1:-$HOME/.private}"
  local DST="${2:-$HOME/private}"
  local SIG="${3:-$HOME/.ecryptfs/private.sig}"
  local KEY="$(cat "$SIG" 2>/dev/null | head -n 1)"
  mkdir -p "$DST"
  mount_ecryptfs "$SRC" "$DST" "$KEY"
}
umount_private_ecryptfs() {
  local DST="${1:-$HOME/private}"
  umount_ecryptfs "$DST"
}

# Mount helpers
ecryptfs_wrap_passphrase() {
  local FILE="${1:-$HOME/.ecryptfs/wrapped-passphrase}"
  ( stty -echo; printf "Passphrase: " 1>&2; read PASSWORD; stty echo; echo "$PASSWORD"; ) |
    xargs printf "%s\n%s" $(od -x -N 100 --width=30 /dev/random | head -n 1 | sed "s/^0000000//" | sed "s/\s*//g") |
    ecryptfs-wrap-passphrase "$FILE"
}
ecryptfs_unwrap_passphrase() {
  local FILE="${1:-$HOME/.ecryptfs/wrapped-passphrase}"
  ( stty -echo; printf "Passphrase: " 1>&2; read PASSWORD; stty echo; echo "$PASSWORD"; ) |
    ecryptfs-insert-wrapped-passphrase-into-keyring "$FILE" -
}

# User mount ecryptfs (no root)
# Mount options are hardcoded: AES, key 16b
user_mount_ecryptfs() {
  local SRC="${1:?Missing source directory...}"
  local DST="${2:?Missing dest directory...}"
  local KEY1="${3:?Missing content key...}"
  local KEY2="${4:-$KEY1}"
  local CONFNAME="${5:-private}"
  local CONF="$HOME/.ecryptfs/$CONFNAME.conf"
  local SIG="$HOME/.ecryptfs/$CONFNAME.sig"
  chmod 700 "$HOME/.ecryptfs"
  ecryptfs-add-passphrase --fnek
  echo "$SRC $DST ecryptfs" > "$CONF"
  echo "$KEY1" > "$SIG"
  echo "$KEY2" >> "$SIG"
  mount.ecryptfs_private "$CONFNAME"
  chmod 500 "$HOME/.ecryptfs"
}
user_umount_ecryptfs() {
  local CONFNAME="${1:-private}"
  umount.ecryptfs_private "$CONFNAME"
  keyctl clear @u
}

# Private user mount wrappers
user_mount_private() {
  local SRC="${1:-$HOME/.private}"
  local DST="${2:-$HOME/private}"
  local SIG="${3:-$HOME/.ecryptfs/private.sig}"
  local KEY="$(cat "$SIG" 2>/dev/null | head -n 1)"
  local CONFNAME="${4:-$(basename "$DST")}"
  mkdir -p "$DST"
  user_mount_ecryptfs "$SRC" "$DST" "$KEY" "" "$CONFNAME"
}
user_umount_private() {
  local DST="${1:-$HOME/private}"
  user_umount_ecryptfs "$(basename "$DST")"
}

#####################################
# Mount encfs
mount_encfs() {
  local SRC="${1:?Missing source directory...}"
  local DST="${2:?Missing dest directory...}"
  local KEY="${3:?Missing encfs key...}"
  local PASSFILE="${4}"
  shift $(min 4 $#)
  ENCFS6_CONFIG="$(readlink -f "$KEY")" sudo -E encfs -o nonempty ${PASSFILE:+--extpass='cat "$PASSFILE"'} "$@" "$SRC" "$DST"
}
umount_encfs() {
  fusermount -u "${1:?Missing mounted directory...}"
}
mount_private_encfs() {
  local SRC="${1:-$HOME/.private}"
  local DST="${2:-$HOME/private}"
  mkdir -p "$DST"
  mount_encfs "$SRC" "$DST" "$KEY"
}
umount_private_encfs() {
  umount_encfs "${1:-$HOME/private}"
}

#####################################
# Mount iso
mount_iso() {
  sudo mount -o loop -t iso9660 "$@"
}

# bin/cue to iso
conv_bin2iso() {
  local BIN="${1:?Missing BIN file...}"
  local CUE="${2:-${BIN%.*}.cue}"
  local ISO="${3:-${BIN%.*}.iso}"
  shift $(($#>=3?3:$#))
  if [ ! -e "$CUE" ]; then
    # MODE1 is the track mode when it is a computer CD
    # MODE2 if it is a PlayStation CD.
    cat > "$CUE" <<EOF
FILE \"$BIN\" BINARY
TRACK 01 MODE1/2352
INDEX 01 00:00:00
EOF
  fi
  bchunk "$@" "$BIN" "$CUE" "$ISO"
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

#####################################
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

#####################################
# Toggle autofs
autofs_toggle() {
  sudo service autofs stop
  for MOUNT; do
    sudo umount -l "$MOUNT"
  done
  sleep 5s
  sudo service autofs start   
}

#####################################
# Check logged on users have a local home
nfs_who() {
  for LOGGED_USER in $(who | awk '{print $1}' | sort | uniq); do
    if [ -f /etc/exports ] && ! command grep -E "^[^#]*$LOGGED_USER" /etc/exports >/dev/null; then
      echo "WARNING: user $LOGGED_USER is logged in using a remote home..."
    fi
  done
}

#####################################
# Mount sshfs
alias umount_sshfs='fusermount -u'
alias mount_sshfs='sshfs -o cache=yes -o kernel_cache -o compression=no -o large_read'
alias mount_sshfs_fast='sshfs -o cache=yes -o kernel_cache -o compression=no -o large_read -o Ciphers=arcfour'

#####################################
# Mount & exec command
mount_exec() {
  local MOUNT="${1:?No mount specified...}"
  shift
  if mountpoint -q "$MOUNT"; then
    eval "$@"
  else
    trap "sudo umount -l '$MOUNT'" INT
    sudo mount "$MOUNT" &&
    eval "$@"
    sudo umount -l "$MOUNT"
    trap INT
  fi
}
