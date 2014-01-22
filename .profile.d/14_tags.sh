#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
#CTAGS_OPTS="-R --c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --sort=foldcase --c++-kinds=f --c-kinds=f"
#CTAGS_OPTS="-R --sort=foldcase --fields=+iaS --extra=+q --c++-kinds=f --c-kinds=f --exclude='.svn' --exclude='.git'"
#CTAGS_OPTS="-R --sort=foldcase --fields=+iaS --extra=+q --exclude='.svn' --exclude='.git'"
CTAGS_OPTS="-R --sort=yes --fields=+iaS --extra=+q --exclude='.svn' --exclude='.git'"

# Cscope default settings
CSCOPE_OPTS="-Rqb"
CSCOPE_REGEX=".*\.c|.*\.h|.*\.cc|.*\.cpp|.*\.hpp"

# Make ctags
function mkctags() {
  # Get directories, remove ~/
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
  # Get options
  CTAGS_OPTIONS="$CTAGS_OPTS $3"
  CTAGS_DB="${DST}/tags"
  # Build tag file
  ${DBG} ctags $CTAGS_OPTIONS -f "${CTAGS_DB}" "${SRC}"
  #echo ${CTAGS_DB}
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
  # Build tag file
  set -f
  find "$SRC" -regextype "posix-egrep" ${@:4} -regex "$CSCOPE_REGEX" -printf '"%p"\n' > "$CSCOPE_FILES"
  ${DBG} cscope $CSCOPE_OPTIONS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
  set +f
  #rm "$CSCOPE_FILES"
  #echo $CSCOPE_DB
}

# Make id-utils database
function mkids() {
  # Get directories
  SRC="$(eval echo ${1:-$PWD})"
  DST="$(eval echo ${2:-$PWD})"
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
