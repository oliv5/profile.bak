#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts
DBG=""

# Ctags settings (see ~/.ctags)
CTAGS_OPTS='-R'

# Cscope default settings
#CSCOPE_OPTS='-qb'
CSCOPE_OPTS='-qbk'
CSCOPE_REGEX='.*\.(h|c|cc|cpp|hpp|inc|S)$'
CSCOPE_EXCLUDE='-not -path *.svn* -and -not -path *.git -and -not -path /tmp/'

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
  #${DBG} $(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}" 2>&1 >/dev/null | \
  #  grep -vE 'Warning: Language ".*" already defined'
  ${DBG} $(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}"
}

# Scan directory for cscope files
scancsdir() {
  command -v >/dev/null cscope || return
  # Get directories, remove ~/
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
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_OPTIONS="$CSCOPE_OPTS $3"
  local CSCOPE_FILES="$DST/cscope.files"
  local CSCOPE_DB="$DST/cscope.out"
  # Build file list
  if [ ! -s $CSCOPE_FILES ]; then
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
  # Get directories, remove ~/
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

# Make id-utils db
mkids() {
  command -v >/dev/null mkid || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # build db
  ( cd "$SRC"
    mkid -o "$DST/ID"
  )
}

# Make pycscope db
mkpycscope() {
  command -v >/dev/null pycscope || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Build tag file
  pycscope -R -f "$DST/pycscope.out" "$SRC"
}

# Make tags and cscope db
mktags() {
  mkctags "$@"
  mkcscope "$@"
  mkids "$@"
  mkpycscope "$@"
}

_rmtags() {
  # Get directories, remove ~/
  local PREFIX="${1:?No file prefix specified}"
  local DIR="$(eval echo ${2:-$PWD})"
  shift 2
  local FILES="$DIR/$@"
  # Rm files
  eval rm -v "${FILES}" 2>/dev/null
}

# Clean ctags
rmctags() {
  _rmtags tags "$@"
}

# Clean cscope db
rmcscope() {
  _rmtags "cscope.out*" "$@"
  _rmtags cscope.files "$@"
}

# Clean id-utils db
rmids() {
  _rmtags ID "$@"
}

# Clean pycscope db
rmpycscope() {
  _rmtags pycscope.out "$@"
}

# Clean tags and cscope db
rmtags() {
  rmctags "$@"
  rmcscope "$@"
  rmids "$@"
  rmpycscope "$@"
}

mkalltags() {
  (
    local SRC
    for TAGPATH in $(find -L "$(readlink -m "${1:-$PWD}")" -maxdepth ${2:-5} -type f -name ".*.path" 2>/dev/null); do
      echo "** Processing file $TAGPATH"
      cd "$(dirname $TAGPATH)"
      local TAGNAME="$(basename $TAGPATH)"
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".ctags.path" ]; then
        rmctags
        for SRC in $(cat $TAGNAME); do
          echo "[ctags] add: $SRC"
          mkctags "$SRC" . "-a"
        done
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".cscope.path" ]; then
        rmcscope
        for SRC in $(cat $TAGNAME); do
          echo "[cscope] add: $SRC"
          scancsdir "$SRC" .
        done
        mkcscope "$SRC" .
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".id.path" ]; then
        rmids
        for SRC in $(cat $TAGNAME); do
          echo "[id] add: $SRC"
          mkids "$SRC" .
        done
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".pycscope.path" ]; then
        rmpycscope
        for SRC in $(cat $TAGNAME); do
          echo "[pycscope] add: $SRC"
          mkpycscope "$SRC" .
        done
      fi
      echo "** Done."
    done
  )
}
