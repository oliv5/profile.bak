#!/bin/sh

################################
# Smartmontools HD checks
smart_basicstest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Check the disk's overall health
  sudo smartctl -H "$DEV"
}

smart_shorttest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Short, but more extensive test
  sudo smartctl -t short "$DEV"
}

smart_longtest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Long test
  sudo smartctl -t short "$DEV"
  # Check results
  sudo smartctl -l selftest "$DEV"
}

################################
# Filesystem commands
fsck_force(){
  sudo touch /forcefsck
}
fsck_repair() {
  local DEV="${1:?No device specified...}"
  if mountpoint "$DEV" >/dev/null && ! sudo umount "$DEV"; then
    echo "Cannot umount '$DEV'. Abort..."
    return 1
  fi
  sudo fsck -y "$DEV"
}

################################
# Find garbage files
ff_garbage() {
  ( set -vx
    printf "Home garbage\n"
    find "$HOME" -type f -name "*~" -print
    ls "${HOME}"/.macromedia/* "${HOME}"/.adobe/*
    printf "\nSystem coredumps\n"
    sudo find /var -type f -name "core" -print
    printf "\nTemporary files\n"
    sudo ls /tmp
    sudo ls /var/tmp
    printf "\nLogs\n"
    sudo du -a -b /var/log | sort -n -r | head -n 10
    sudo ls /var/log/*.gz
    printf "\nOpened but deleted\n"
    sudo lsof -nP | grep '(deleted)'
    sudo lsof -nP | awk '/deleted/ { sum+=$8 } END { print sum }'
    sudo lsof -nP | grep '(deleted)' | awk '{ print $2 }' | sort | uniq
  )
}

lsof_deleted() {
    sudo lsof -nP | grep '(deleted)'
}

lsof_close(){
  # For all open but deleted files associated with process 2746, trunctate the file to 0 bytes
  local PID="${1:?No PID specified...}"
  cd /proc/$PID/fd 
  ls -l | grep '(deleted)' | awk '{ print $9 }' | while read FILE; do :> /proc/$PID/fd/$FILE; done
}

##############################
# Find duplicate files
alias ff_dup='find_duplicates'
find_duplicates() {
  local TMP1="$(tempfile)"
  local TMP2="$(tempfile)"
  for DIR in "${@:-.}"; do
    find "${DIR:-.}" -type f -exec md5sum {} \; >> "$TMP1"
  done
  awk '{print $1}' "$TMP1" | sort | uniq -d > "$TMP2"
  while read SUM; do
    grep "$SUM" "$TMP1" | cut -d ' ' -f 2- | xargs
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}

# Find empty directories
alias fd_empty='find . -type d -empty'
alias ff_empty='find . -type f -empty'

################################
# http://unix.stackexchange.com/questions/59112/preserve-directory-structure-when-moving-files-using-find
# Move by replicating directory structure
mkdir_mv() {
  local SRC="$1"
  local DST="$(path_abs "${2:-.}")"
  shift 2
  local BASENAME="$(basename "$SRC")"
  find "$(dirname "$SRC")" -name "${BASENAME:-*}" $@ -exec sh -c '
      for x; do
        mkdir -p "$0/${x%/*}" &&
        mv "$x" "$0/$x"
      done
    ' "$DST" {} +
}

################################
# Rsync replicate tree (without files)
alias rsync_mktree='rsync -a -f"+ */" -f"- *"'
# Rsync copy tree (with files)
alias rsync_cptree='rsync -a'
# Rsync copy file (with tree)
alias rsync_cp='rsync -R'
# Rsync move file (with tree)
alias rsync_mv='rsync -R --remove-source-files'

##############################
# Duplicate file or directory with incremental num
bak() {
  for FILE; do
    cp -v "$FILE" "${FILE}.$(ls -1 "$FILE".* 2>/dev/null | wc -l)"
  done
}

# Duplicate files or directory with date
bak_date() {
  local DATE="$(date +%Y%m%d-%H%M%S)"
  for FILE; do
    cp -v "$FILE" "${FILE}.${DATE}.bak"
  done
}

# Unlink - overwrites the unlink legacy tool
unlink() {
  for FILE; do
    cp --remove-destination "$(readlink "$FILE")" "$FILE"
  done
}

# Swap files or directories
swap() {
  local FILE1="${1:?Nothing to swap...}"
  local FILE2="${2:?Nothing to swap...}"
  local TMP
  [ -d "$FILE2" ] && TMP="$(mktemp --tmpdir="$PWD" -d)" || TMP="$(mktemp --tmpdir="$PWD")"
  mv "$FILE2" "$TMP"
  mv "$FILE1" "$FILE2"
  mv "$TMP" "$FILE1"
}

################################
# dd utils
dd_status() {
  kill -10 $(pgrep '^dd$')
}

################################
# Make iso from block device
mk_iso() {
  dd if="${1:-/dev/cdrom}" of="${2:-./myimage.iso}" conv=noerror
}

# Make iso from filesystem
mk_isofs() {
  mkisofs -o "${2:-./myimage.iso}" "${1:?No input directory specified...}"
}

# Diff iso versus source
diff_iso() {
  local SRC="${1:?No iso specified...}"
  local REF="${2:?No filesystem to check against...}"
  local MOUNT="${3:-/mnt}"
  mount_iso "$SRC" "$MOUNT"
  diff -rq "$MOUNT" "$REF"
  local RES=$?
  sudo umount "$MOUNT"
  return $RES
}

# Check iso file read
check_iso() {
  local SRC="${1:?No iso specified...}"
  local MOUNT="${2:-/mnt}"
  mount_iso "$SRC" "$MOUNT"
  find "$MOUNT" -type f -print0 | xargs -0 -n1 -I{} cat "{}" > /dev/null
  local RES=$?
  sudo umount "$MOUNT"
  return $RES
}
check_alliso() {
  local MOUNT="${MOUNT:-/mnt}"
  local FAILED=""
  sudo true
  for SRC; do
    echo -n "Check '$SRC' ... "
    if check_iso "$SRC" "$MOUNT" 2>/dev/null; then
      echo "success."
    else
      echo "FAILURE."
    fi
  done
}
