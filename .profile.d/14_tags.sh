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
function mkctags() {
  command -v >/dev/null ctags || return
  # Get directories, remove ~/
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CTAGS_OPTIONS="$CTAGS_OPTS $3"
  CTAGS_DB="${DST}/tags"
  # Build tag file
  ${DBG} $(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}"
}

# Scan directory for cscope files
function scancsdir() {
  command -v >/dev/null cscope || return
  # Get directories
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CSCOPE_FILES="$DST/cscope.files"
  # Scan directory
  set -f
  find "$SRC" $CSCOPE_EXCLUDE ${@:3} -regextype posix-egrep -regex "$CSCOPE_REGEX" -type f -printf '"%p"\n' >> "$CSCOPE_FILES"
  set +f
}

# Make cscope db from source list file
function mkcscope-1() {
  command -v >/dev/null cscope || return
  # Get directories
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CSCOPE_OPTIONS="$CSCOPE_OPTS $3"
  CSCOPE_FILES="$DST/cscope.files"
  CSCOPE_DB="$DST/cscope.out"
  # Build file list
  if [ ! -e $CSCOPE_FILES ]; then
    scancsdir "$SRC" "$DST" ${@:4}
  fi
  # Build tag file
  ${DBG} $(which cscope) $CSCOPE_OPTIONS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
}

# Scan and make cscope db
# Warning: this is not incremental
# It erases the old database and rebuild it
function mkcscope-2() {
  command -v >/dev/null cscope || return
  # Get directories
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CSCOPE_OPTIONS="$CSCOPE_OPTS $3"
  CSCOPE_DB="$DST/cscope.out"
  # Build tag file
  find "$SRC" $CSCOPE_EXCLUDE ${@:4} -regextype posix-egrep -regex "$CSCOPE_REGEX" -type f -printf '"%p"\n' | \
    ${DBG} $(which cscope) $CSCOPE_OPTIONS -i '-' -f "$CSCOPE_DB"
}

# Cscope alias - use a fct because aliases are not exported to other fct
function mkcscope() {
  mkcscope-1 "$@"
}

# Make id-utils database
function mkids() {
  command -v >/dev/null mkid || return
  # Get directories
  SRC="$(eval readlink -f ${1:-$PWD})"
  DST="$(eval readlink -f ${2:-$PWD})"
  # build db
  pushd "$SRC" >/dev/null
  mkid -o "$DST/ID"
  popd >/dev/null
}

# Make tags and cscope db
function mktags() {
  mkctags "$@"
  mkcscope "$@"
  mkids "$@"
}

# Clean ctags
function rmctags() {
  DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR:?No directory specified}/tags" 2>/dev/null
}

# Clean cscope db
function rmcscope() {
  DIR="$(eval echo ${1:-$PWD})"
  FILE="${DIR}/cscope"
  rm -v "${FILE:?No directory specified}.out"* 2>/dev/null
  rm -v "${FILE:?No directory specified}.files" 2>/dev/null
}

# Clean id-utils db
function rmids() {
  DIR="$(eval echo ${1:-$PWD})"
  FILE="${DIR}/ID"
  rm -v "${FILE:?No directory specified}" 2>/dev/null
}

# Clean tags and cscope db
function rmtags() {
  rmctags "$@"
  rmcscope "$@"
  rmids "$@"
}

function mkalltags() {
  _PWD="$PWD"
  for TAGPATH in $(find -L "$(readlink -m "${1:-$PWD}")" -maxdepth ${2:-5} -type f -name "*.path" 2>/dev/null); do
    echo "** Processing file $TAGPATH"
    set -x
    builtin cd "$(dirname $TAGPATH)"
    set +x
    pwd
    TAGNAME="$(basename $TAGPATH)"
    if [ "$TAGNAME" == "tags.path" -o "$TAGNAME" == "ctags.path" ]; then
      rmctags
      for SRC in $(cat $TAGNAME); do
        echo "[ctags] add: $SRC"
        mkctags "$SRC" . "-a"
      done
    fi
    if [ "$TAGNAME" == "tags.path" -o "$TAGNAME" == "cscope.path" ]; then
      rmcscope
      for SRC in $(cat $TAGNAME); do
        echo "[cscope] add: $SRC"
        scancsdir "$SRC" .
      done
      mkcscope "$SRC" .
    fi
    if [ "$TAGNAME" == "tags.path" -o "$TAGNAME" == "id.path" ]; then
      rmids
      for SRC in $(cat $TAGNAME); do
        echo "[id] add: $SRC"
        mkids "$SRC" .
      done
    fi
    echo -e "** Done.\n"
  done
  builtin cd "$_PWD"
}
