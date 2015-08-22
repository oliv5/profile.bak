#!/bin/sh

# Check bup repository
bup_exists(){
  BUP_DIR="${BUP_DIR:-.}"
  git --git-dir="$BUP_DIR" rev-parse >/dev/null 2>&1
}

# Init bup directory
bup_init() {
  local SERVER=${1:+-r "$1"}
  shift
  if bup_exists; then
    echo "Skip existing repo in '$BUP_DIR'"
  else
    bup init ${SERVER} "$@"
  fi
}

# Make a backup
bup_backup() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?No directory to backup...}"
  local SERVER=${3:+-r "$3"}
  shift 3
  bup index "$SRC"
  bup save $SERVER -n "$BRANCH" "$SRC"
}

# Restore a backup
bup_restore() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?No directory to restore...}"
  local DST="${3:?No output directory...}"
  local REV="${4:-latest}"
  shift 4
  bup restore -C "$DST" "$BRANCH/$REV/$SRC" "$@"
}

# Get backup list
bup_list() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  shift 1
  bup ls "$BRANCH"
}

# Protect with PAR2
alias bup_protect='bup fsck -g'

# Make a tar backup
bup_tar() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  local SRC="${2:?No directory to backup...}"
  shift 2
  bup index "$SRC"
  tar -cvf --exclude-vcs - "$SRC" | bup split -n "$BRANCH" -vv
}

# Restore from tar backup
bup_untar() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  shift 1
  bup join "$BRANCH" | tar -tf -
}

# Show tar backup list
bup_listtar() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  shift 1
  GIT_DIR="$BUP_DIR" git log "$BRANCH"
}

# Get repo size
bup_size() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  du -s "$BUP_DIR"
}

# Encrypt a bup repo
bup_encrypt() {
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local ARCHIVE="${1:?No output archive specified...}"
  local KEY="${2:?No encryption key specified...}"
  tar -cf - "$BUP_DIR" | gpg --encrypt --batch --yes --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
bup_decrypt(){
  local ARCHIVE="${1:?No input archive specified...}"
  local DIR="${2:-${BUP_DIR:-.}}"
  gpg --decrypt "$ARCHIVE" | tar -xvf - -C "$DIR"
}

