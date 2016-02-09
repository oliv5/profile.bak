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
# Move/copy by replicating directory structure
alias mkdir_cp='_mkdir_exec "cp -v"'
alias mkdir_mv='_mkdir_exec "mv -v"'
_mkdir_exec() {
  local EXEC="${1:-echo}"
  local SRC="$2"
  local DST="$(path_abs "${3:-.}")"
  shift 3
  local BASENAME="$(basename "$SRC")"
  find "$(dirname "$SRC")" ${BASENAME:+-name "$BASENAME"} $@ -exec sh -c '
      EXEC="$1"
      shift
      for x do
        mkdir -p "$0/${x%/*}" &&
        $EXEC "$x" "$0/$x"
      done
    ' "$DST" "$EXEC" {} +
}

##############################
# Backup directory or file
bak() {
  for FILE; do
    cp -v "$FILE" "${FILE}.$(ls -1 "$FILE".* | wc -l)"
  done
}

################################
# dd utils
dd_status() {
  kill -10 $(pgrep '^dd$')
}
