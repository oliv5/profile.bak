#!/bin/sh

################################
# File size
alias fsize='stat -L -c %s'

################################
# http://unix.stackexchange.com/questions/59112/preserve-directory-structure-when-moving-files-using-find
# Move by replicating directory structure
# See also rsync_mktree
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
# Rsync
alias rsync_cp='rsync -a' # Recursive copy
alias rsync_mv='rsync -a --remove-source-files' # Recursive move
alias rsync_mktree='rsync -a -f"+ */" -f"- *"'  # Replicate tree
alias rsync_cptree='rsync -R' # Copy & keep relative tree
alias rsync_mvtree='rsync -R --remove-source-files' # Move & keep relative tree
alias rsync_timestamp='rsync -rt --size-only --existing' # Update timestamps only

##############################
# Copy files & preserve permissions
cp_tar() {
  tar cvfp - "${1:?No source specified...}" | ( cd "${2:?No destination specified...}/" ; tar xvfp - )
}
cp_cpio() {
  find "${1:?No source directory specified...}/" -print -depth | cpio -pdm "${2:?No destination directory specified...}/"
}
ssh_cpout() {
  find "${1:?No local source directory specified...}/" -depth -print | cpio -oaV | ssh "${2:?No remote destination user@host:port/directory specified...}/" 'cpio -imVd'
}
ssh_cpin() {
  ssh "${1:?No remote source user@host:port/directory specified...}/" "find \"${2:?No local destination directory specified...}/\" -depth -print | cpio -oaV" | cpio -imVd
}

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

##############################
# Unlink - overwrites the unlink legacy tool
unlink() {
  for FILE; do
    LINK="$(readlink "$FILE")"
    [ -n "$LINK" ] && cp --remove-destination "$LINK" "$FILE"
  done
}

##############################
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
# Move files from multiple sources while filtering extensions
# ex: EXCLUDE="temp *.bak" movefiles $DST/ $SRC1/ $SRC2/
movefiles() {
  local DST="${1?No destination specified...}"; shift
  local OPT=""; for EXT in $EXCLUDE; do OPT="${OPT:+$OPT }--exclude=$EXT"; done
  for SRC; do
    rsync -av --progress --remove-source-files --prune-empty-dirs $OPT "$SRC/" "$DST" 2>/dev/null
  done
}

# Move files from mounted drives
movefiles_mnt() {
  local MNT="${1?No mountpoint specified...}"; shift
  sudo mount "$MNT" && 
    movefiles "$@"
}
