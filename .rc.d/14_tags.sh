#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts
DBG=""

# Ctags settings
CTAGS_OPTS="-R --sort=yes --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+qf --exclude='.svn' --exclude='.git' --exclude='tmp'"

# Cscope default settings
#CSCOPE_OPTS="-qb"
CSCOPE_OPTS="-qbk"
CSCOPE_REGEX='.*\.(h|c|cc|cpp|hpp|inc|S|py)$'
CSCOPE_EXCLUDE="-not -path *.svn* -and -not -path *.git -and -not -path /tmp/"

# Make ctags
mkctags() {
  command -v >/dev/null ctags || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CTAGS_OPTIONS="$CTAGS_OPTS $3"
  local CTAGS_DB="${DST}/tags"
  # Build tag file
  ${DBG} $(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}" 2>&1 >/dev/null | \
    grep -vE 'Warning: Language ".*" already defined'
}

# Scan directory for cscope files
scancsdir() {
  command -v >/dev/null cscope || return
  # Get directories
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_FILES="$DST/cscope.files"
  shift $(min 2 $#)
  # Scan directory
  ( set -f; find "$SRC" $CSCOPE_EXCLUDE "$@" -regextype posix-egrep -regex "$CSCOPE_REGEX" -type f -printf '"%p"\n' >> "$CSCOPE_FILES" )
}

# Make cscope db from source list file
mkcscope_1() {
  command -v >/dev/null cscope || return
  # Get directories
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_OPTIONS="$CSCOPE_OPTS $3"
  local CSCOPE_FILES="$DST/cscope.files"
  local CSCOPE_DB="$DST/cscope.out"
  # Build file list
  if [ ! -e $CSCOPE_FILES ]; then
    shift $(min 3 $#)
    scancsdir "$SRC" "$DST" "$@"
  fi
  # Build tag file
  ${DBG} $(which cscope) $CSCOPE_OPTIONS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
}

# Scan and make cscope db
# Warning: this is not incremental
# It erases the old database and rebuild it
mkcscope_2() {
  command -v >/dev/null cscope || return
  # Get directories
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_OPTIONS="$CSCOPE_OPTS $3"
  local CSCOPE_DB="$DST/cscope.out"
  shift $(min 3 $#)
  # Build tag file
  find "$SRC" $CSCOPE_EXCLUDE "$@" -regextype posix-egrep -regex "$CSCOPE_REGEX" -type f -printf '"%p"\n' | \
    ${DBG} $(which cscope) $CSCOPE_OPTIONS -i '-' -f "$CSCOPE_DB"
}

# Cscope alias - use a fct because aliases are not exported to other fct
mkcscope() {
  mkcscope_1 "$@"
}

# Make id-utils database
mkids() {
  command -v >/dev/null mkid || return
  # Get directories
  local SRC="$(eval readlink -f ${1:-$PWD})"
  local DST="$(eval readlink -f ${2:-$PWD})"
  # build db
  local _PWD="$PWD"
  cd "$SRC"
  mkid -o "$DST/ID"
  cd "$_PWD"
}

# Make tags and cscope db
mktags() {
  mkctags "$@"
  mkcscope "$@"
  mkids "$@"
}

# Clean ctags
rmctags() {
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR:?No directory specified}/tags" 2>/dev/null
}

# Clean cscope db
rmcscope() {
  local DIR="$(eval echo ${1:-$PWD})"
  local FILE="${DIR}/cscope"
  rm -v "${FILE:?No directory specified}.out"* 2>/dev/null
  rm -v "${FILE:?No directory specified}.files" 2>/dev/null
}

# Clean id-utils db
rmids() {
  local DIR="$(eval echo ${1:-$PWD})"
  local FILE="${DIR}/ID"
  rm -v "${FILE:?No directory specified}" 2>/dev/null
}

# Clean tags and cscope db
rmtags() {
  rmctags "$@"
  rmcscope "$@"
  rmids "$@"
}

mkalltags() {
  local _PWD="$PWD"
  local SRC
  for TAGPATH in $(find -L "$(readlink -m "${1:-$PWD}")" -maxdepth ${2:-5} -type f -name "*.path" 2>/dev/null); do
    echo "** Processing file $TAGPATH"
    cd "$(dirname $TAGPATH)"
    local TAGNAME="$(basename $TAGPATH)"
    if [ "$TAGNAME" = "tags.path" -o "$TAGNAME" = "ctags.path" ]; then
      rmctags
      for SRC in $(cat $TAGNAME); do
        echo "[ctags] add: $SRC"
        mkctags "$SRC" . "-a"
      done
    fi
    if [ "$TAGNAME" = "tags.path" -o "$TAGNAME" = "cscope.path" ]; then
      rmcscope
      for SRC in $(cat $TAGNAME); do
        echo "[cscope] add: $SRC"
        scancsdir "$SRC" .
      done
      mkcscope "$SRC" .
    fi
    if [ "$TAGNAME" = "tags.path" -o "$TAGNAME" = "id.path" ]; then
      rmids
      for SRC in $(cat $TAGNAME); do
        echo "[id] add: $SRC"
        mkids "$SRC" .
      done
    fi
    echo "** Done."
  done
  cd "$_PWD"
}
