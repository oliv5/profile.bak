#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
_CTAGS_OPTS='-R --extra=f'
_CTAGS_OUT='.tags'

# Cscope settings
#_CSCOPE_OPTS='-qb'
_CSCOPE_OPTS='-qbk'
_CSCOPE_REGEX='.*\.(h|c|cc|cpp|hpp|inc|S)$'
_CSCOPE_EXCLUDE='-not -path *.svn* -and -not -path *.git -and -not -path /tmp/'
_CSCOPE_OUT='.cscope.out'
_CSCOPE_FILES='.cscope.files'

# ID settings
_ID_OUT='.id'

# pycscope settings
_PYCSCOPE_OUT='.pycscope.out'

# Make ctags
mkctags() {
  command -v >/dev/null ctags || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CTAGS_OPTIONS="$_CTAGS_OPTS $3"
  local CTAGS_DB="${DST}/${_CTAGS_OUT}"
  # Build tag file
  #$(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}" 2>&1 >/dev/null | \
  #  grep -vE 'Warning: Language ".*" already defined'
  command ctags $CTAGS_OPTIONS -f "${CTAGS_DB}" "${SRC}"
  ln -fs "${CTAGS_DB}" "${DST}/tags"
}

# Scan directory for cscope files
scancsdir() {
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_FILES="$DST/${_CSCOPE_FILES}"
  # Scan directory
  ( set -f; find "$SRC" $_CSCOPE_EXCLUDE -regextype posix-egrep -regex "$_CSCOPE_REGEX" -type f -printf '"%p"\n' >> "$CSCOPE_FILES" )
}

# Make cscope db from source list file
mkcscope_1() {
  command -v >/dev/null cscope || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Get options
  local CSCOPE_OPTIONS="$_CSCOPE_OPTS $3"
  local CSCOPE_FILES="$DST/${_CSCOPE_FILES}"
  local CSCOPE_DB="$DST/${_CSCOPE_OUT}"
  # Build file list
  if [ ! -e $CSCOPE_FILES ]; then
    scancsdir "$SRC" "$DST"
  fi
  # Build tag file
  command cscope $CSCOPE_OPTIONS -i "$CSCOPE_FILES" -f "$CSCOPE_DB"
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
  local CSCOPE_OPTIONS="$_CSCOPE_OPTS $3"
  local CSCOPE_DB="$DST/${_CSCOPE_OUT}"
  # Build tag file
  find "$SRC" $_CSCOPE_EXCLUDE -regextype posix-egrep -regex "$_CSCOPE_REGEX" -type f -printf '"%p"\n' | \
    command cscope $CSCOPE_OPTIONS -i '-' -f "$CSCOPE_DB"
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
    command mkid -o "$DST/${_ID_OUT}"
  )
}

# Make pycscope db
mkpycscope() {
  command -v >/dev/null pycscope || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Build tag file
  command pycscope -R -f "$DST/${_PYCSCOPE_OUT}" "$SRC"
}

# Make gtags files
mkgtags() {
  command -v >/dev/null gtags || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  # Build tag file
  if [ -z "$1" ]; then
    gtags "$DST"
  else
    find "$SRC" -type f -print | gtags -f - "$DST"
  fi
}

# Make tags and cscope db
mktags() {
  mkctags "$@"
  mkgtags "$@"
  mkcscope "$@"
  mkids "$@"
  mkpycscope "$@"
}

# Clean ctags
rmctags() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_CTAGS_OUT}" "${DIR}/tags" 2>/dev/null
}

# Clean cscope db
rmcscope() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_CSCOPE_OUT}"* "${DIR}/${_CSCOPE_FILES}" 2>/dev/null
}

# Clean id-utils db
rmids() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_ID_OUT}" 2>/dev/null
}

# Clean pycscope db
rmpycscope() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_PYCSCOPE_OUT}" 2>/dev/null
}

# Clean gtags files
rmgtags() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/GPATH" "${DIR}/GRTAGS" "${DIR}/GSYMS" "${DIR}/GTAGS" 2>/dev/null
}

# Clean tags and cscope db
rmtags() {
  rmctags "$@"
  rmgtags "$@"
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
