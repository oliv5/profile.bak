#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
#CTAGS_OPTS="-R --c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --sort=foldcase --c++-kinds=f --c-kinds=f"
#CTAGS_OPTS="-R --sort=foldcase --fields=+iaS --extra=+q --c++-kinds=f --c-kinds=f --exclude='.svn' --exclude='.git'"
#CTAGS_OPTS="-R --sort=foldcase --fields=+iaS --extra=+q --exclude='.svn' --exclude='.git'"
CTAGS_OPTS="-R --sort=yes --fields=+iaS --extra=+qf --exclude='.svn' --exclude='.git' --exclude='tmp'"

# Cscope default settings
CSCOPE_OPTS="-Rqb"
CSCOPE_REGEX=".*\.c|.*\.h|.*\.cc|.*\.cpp|.*\.hpp"
CSCOPE_EXCLUDE="-not -path *.svn* -and -not -path *.git -and -not -path /tmp/"

# Make ctags
function mkctags() {
  # Get directories, remove ~/
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CTAGS_OPTIONS="$CTAGS_OPTS $3"
  CTAGS_DB="${DST}/tags"
  # Build tag file
  ${DBG} $(which ctags) $CTAGS_OPTIONS -f "${CTAGS_DB}" "${SRC}"
  #echo ${CTAGS_DB}
}

# Scan a new cscope directory
function scancsdir() {
  # Get directories
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CSCOPE_FILES="$DST/cscope.files"
  # Scan directory
  set -f
  find "$SRC" -regextype "posix-egrep" $CSCOPE_EXCLUDE ${@:3} -regex "$CSCOPE_REGEX" -printf '"%p"\n' >> "$CSCOPE_FILES"
  set +f
}

# Make cscope db
function mkcscope() {
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
  #echo $CSCOPE_DB
}

# Make id-utils database
function mkids() {
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
  rm -v "${DIR}/tags"
}

# Clean cscope db
function rmcscope() {
  DIR="$(eval echo ${1:-$PWD})"
  FILE="${DIR}/cscope"
  rm -v "${FILE}.out"*
  rm -v "${FILE}.files"
}

# Clean id-utils db
function rmids() {
  DIR="$(eval echo ${1:-$PWD})"
  FILE="${DIR}/ID"
  rm -v "${FILE}"
}

# Clean tags and cscope db
function rmtags() {
  rmctags
  rmcscope
  rmids
}
