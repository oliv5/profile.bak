#!/bin/sh

# Check bup repository
bup_exists(){
  local BUP_DIR="${1:-${BUP_DIR:-.}}"
  git --git-dir="$BUP_DIR" rev-parse >/dev/null 2>&1
}

# Init bup directory
bup_init() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists && { echo "Skip existing repo..." && return 1; }
  local SERVER=${1:+-r "$1"}
  shift
  bup init ${SERVER} "$@"
}

# Add file or directory
bup_add() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?Nothing to backup...}"
  local SERVER=${3:+-r "$3"}
  shift 3
  bup index "$SRC"
  bup save $SERVER -n "$BRANCH" "$SRC" "$@"
}

# Restore a backup
bup_restore() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?Nothing to restore...}"
  local DST="${3:?No output directory...}"
  local REV="${4:-latest}"
  shift 4
  bup restore -C "$DST" "$BRANCH/$REV/$SRC" "$@"
}

# Make a tar backup
bup_tar() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  local SRC="${2:?Nothing to backup...}"
  shift 2
  bup index "$SRC"
  tar -cvf --exclude-vcs - "$SRC" | bup split -n "$BRANCH" -vv
}

# Restore from tar backup
bup_untar() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local BRANCH="${1:?No backup branch specified...}"
  local DST="${2:?No output directory...}"
  shift 1
  bup join "$BRANCH" | tar -tf -C "$DST" -
}

# List content
alias bup_ls='bup ls'

# Show git log
alias bup_log='git --git-dir="$BUP_DIR" log'

# Get repo size
alias bup_size='du -s "$BUP_DIR"'

# Protect with PAR2
alias bup_protect='bup fsck -g'

# Encrypt a bup repo
bup_encrypt() {
  local BUP_DIR="${BUP_DIR:-.}"
  bup_exists || { echo "Not a bup directory..."; return 1; }
  local ARCHIVE="${1:?No output archive specified...}"
  local KEY="${2:?No encryption key specified...}"
  tar -cf - "$BUP_DIR" | gpg --encrypt --batch --yes --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
bup_decrypt(){
  local BUP_DIR="${BUP_DIR:-.}"
  local ARCHIVE="${1:?No input archive specified...}"
  local DIR="${2:-${BUP_DIR:-.}}"
  gpg --decrypt "$ARCHIVE" | tar -xvf - -C "$DIR"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#bup}" != "$1" ] && "$@" || true
