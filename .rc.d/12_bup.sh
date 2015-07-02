#!/bin/sh

# Init bup directory
bup_init() {
  local SERVER=${1:+-r "$1"}
  shift
  bup init ${SERVER} "$@"
}

# Make a backup
bup_backup() {
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?No directory to backup...}"
  local SERVER=${3:+-r "$3"}
  shift 3
  bup index "$SRC"
  bup save $SERVER -n "$BRANCH" "$SRC"
}

# Restore a backup
bup_restore() {
  local BRANCH="${1:?No backup branch...}"
  local SRC="${2:?No directory to restore...}"
  local DST="${3:?No output directory...}"
  local REV="${4:-latest}"
  shift 4
  bup restore -C $DST $BRANCH/$REV/$SRC "$@"
}

# Make a tar backup
bup_tar() {
  local BRANCH="${1:?No backup branch specified...}"
  local SRC="${2:?No directory to backup...}"
  shift 2
  bup index "$SRC"
  tar -cvf - "$SRC" | bup split -n "$BRANCH" -vv
}

# Restore from tar backup
bup_untar() {
  local BRANCH="${1:?No backup branch specified...}"
  shift 1
  bup join "$BRANCH" | tar -tf -
}

# Protect with PAR2
alias bup_protect='bup fsck -g'

# Get repo size
bup_size() {
  du -s ${1:-.}/.bup
}
