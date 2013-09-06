#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
#CTAGS_OPTS="--c++-kinds=+p --fields=+iaS --extra=+q --sort=foldcase -R" # Include header in list
CTAGS_OPTS="--fields=+iaS --extra=+q --sort=foldcase -R"

# Cscope default settings
CSCOPE_OPTS="-bqkv"
CSCOPE_PATH=".*\.c|.*\.h|.*\.cc"

# Make ctags
function mkctags() {
  DIR="${1:-.}"
  if [ -d "${DIR}" ]; then
    echo "Make tags in $(readlink -f $DIR) ${@:2}"
    export CTAGS_DB="${DIR}/tags"
    #rm "${CTAGS_DB}" 2>/dev/null
    ctags $CTAGS_OPTS -f "${CTAGS_DB}" "${DIR}" "${@:2}"
    echo "done"
  fi
}

# Make cscope db
function mkcscope() {
  DIR=$(readlink -f "${1:-$PWD}")
  if [ -d "$DIR" ]; then
    echo "Make cscope in $DIR ${@:2}"
    export CSCOPE_FILES="$DIR/cscope.files"
    export CSCOPE_DB="$DIR/cscope.out"
    #rm "$CSCOPE_DB" 2>/dev/null
    find "$DIR" "${@:2}" -regextype "posix-egrep" -regex "$CSCOPE_PATH" > "$CSCOPE_FILES"
    cscope $CSCOPE_OPTS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
    echo "done"
  fi
}

# Make tags and cscope db
function mkalltags() {
  mkctags "$@"
  mkcscope "$@"
}

# Clean ctags
function rmctags() {
  rm -v "${CTAGS_DB:-tags}"
  unset CTAGS_DB
}

# Clean cscope db
function rmcscope() {
  FILE="${CSCOPE_DB:-cscope}"
  rm -v "${FILE}"
  rm -v "${FILE}.in"
  rm -v "${FILE}.po"
  unset CSCOPE_FILES CSCOPE_DB
}

# Clean tags and cscope db
function rmalltags() {
  rmctags
  rmcscope
}
