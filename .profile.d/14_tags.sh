#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
#CTAGS_OPTS="-R --c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --fields=+iaS --extra=+q --sort=foldcase"
#CTAGS_OPTS="-R --sort=foldcase --c++-kinds=f --c-kinds=f"
CTAGS_OPTS="-R --sort=foldcase --fields=+iaS --extra=+q --c++-kinds=f --c-kinds=f --exclude='.svn' --exclude='.git'"

# Cscope default settings
CSCOPE_OPTS="-bqkv"
CSCOPE_REGEX=".*\.c|.*\.h|.*\.cc"

# Make ctags
function mkctags() {
  # Get directories
  DST=$(readlink -f "${1:-$PWD}")
  SRC=$(readlink -f "${2:-./}")
  # Get options
  CTAGS_OPTS="$CTAGS_OPTS ${@:3}"
  export CTAGS_DB="${DST}/tags"
  # Build tag file
  ${QUIET} echo "Make tags in $DST from $SRC"
  ctags $CTAGS_OPTS -f "${CTAGS_DB}" "${SRC}"
}

# Make cscope db
function mkcscope() {
  # Get directories
  DST=$(readlink -f "${1:-$PWD}")
  SRC=$(readlink -f "${2:-./}")
  # Get options
  CSCOPE_OPTS="$CSCOPE_OPTS $3"
  export CSCOPE_FILES="$DST/cscope.files"
  export CSCOPE_DB="$DST/cscope.out"
  # Build tag file
  set -f
  ${QUIET} echo "Make cscope in $DST from $SRC"
  find "$SRC" -regextype "posix-egrep" ${@:4} -regex "$CSCOPE_REGEX" > "$CSCOPE_FILES"
  cscope $CSCOPE_OPTS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
  set +f
}

# Make tags and cscope db
function mktags() {
  mkctags "$@"
  mkcscope "$@"
}

# Clean ctags
function rmctags() {
  DIR=$(readlink -f "${1:-$PWD}")
  ${QUIET} echo "Remove tags from $DIR"
  rm -v "${DIR}/tags" "${DIR}/tags.*"
  unset CTAGS_DB
}

# Clean cscope db
function rmcscope() {
  DIR=$(readlink -f "${1:-$PWD}")
  ${QUIET} echo "Remove cscope from $DIR"
  FILE="${DIR}/cscope"
  rm -v "${FILE}.out" "${FILE}.files" "${FILE}.in" "${FILE}.po"
  unset CSCOPE_FILES CSCOPE_DB
}

# Clean tags and cscope db
function rmtags() {
  rmctags
  rmcscope
}
