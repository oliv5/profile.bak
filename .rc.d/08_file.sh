#!/bin/sh

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

################################
lsof_deleted() {
    sudo lsof -nP | grep '(deleted)'
}

lsof_close(){
  # For all open but deleted files associated with process 2746, trunctate the file to 0 bytes
  local PID="${1:?No PID specified...}"
  cd /proc/$PID/fd 
  ls -l | grep '(deleted)' | awk '{ print $9 }' | while read FILE; do :> /proc/$PID/fd/$FILE; done
}

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
  local TMP=""; [ -d "$FILE2" ] && TMP="-d"
  TMP="$(mktemp --tmpdir="$PWD" $TMP)"
  mv -fT "$FILE2" "$TMP"
  mv -fT "$FILE1" "$FILE2"
  mv -fT "$TMP" "$FILE1"
}
