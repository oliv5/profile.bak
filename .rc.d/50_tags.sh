#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
_CTAGS_OPTS='--fields=+iaS --extra=+qf --c++-kinds=+p --python-kinds=-i'
_CTAGS_OUT='.tags'

# Cscope settings
_CSCOPE_OPTS='-qbk'
_CSCOPE_REGEX='.*\.(h|c|cc|cpp|hpp|inc|py|S)$'
_CSCOPE_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
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
  shift $(($#<=2?$#:2))
  # Get options
  local CTAGS_OPTIONS="$_CTAGS_OPTS -R $@"
  local CTAGS_DB="${DST}/${_CTAGS_OUT}"
  # Build tag file
  #$(which ctags) $CTAGS_OPTIONS "${CTAGS_DB}" "${SRC}" 2>&1 >/dev/null | \
  #  grep -vE 'Warning: Language ".*" already defined'
  command ctags $CTAGS_OPTIONS -f "${CTAGS_DB}" "${SRC}"
  ln -fs "${CTAGS_DB}" "${DST}/tags"
}

# Scan directory and build cscope file list incrementally
scancsdir() {
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  shift $(($#<=2?$#:2))
  # Get options
  local CSCOPE_FILES="$DST/${_CSCOPE_FILES}"
  # Scan directory
  ( set -f; find -L "$SRC" $_CSCOPE_EXCLUDE -regextype posix-egrep -regex "$_CSCOPE_REGEX" -type f -execdir readlink -e "{}" \; | sed -e 's/\\/\\/g ; s/"/\"/g ; s/^/"/g ; s/$/"/g' >> "$CSCOPE_FILES" )
}

# Make cscope db from source list file (incrementally)
mkcscope() {
  command -v >/dev/null cscope || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  shift $(($#<=2?$#:2))
  # Get options
  local CSCOPE_OPTIONS="$_CSCOPE_OPTS $@"
  local CSCOPE_FILES="$DST/${_CSCOPE_FILES}"
  local CSCOPE_DB="$DST/${_CSCOPE_OUT}"
  # Build file list incrementally
  scancsdir "$SRC" "$DST"
  # Build tag file
  command cscope $CSCOPE_OPTIONS -i "$CSCOPE_FILES" -f "$CSCOPE_DB" &&
    rm "${CSCOPE_DB}.in" "${CSCOPE_DB}.po" 2>/dev/null
}

# Scan and make cscope db
# Warning: this is not incremental
# It erases the old database and rebuild it
mkcscope_clean() {
  command -v >/dev/null cscope || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  shift $(($#<=2?$#:2))
  # Get options
  local CSCOPE_OPTIONS="$_CSCOPE_OPTS $@"
  local CSCOPE_DB="$DST/${_CSCOPE_OUT}"
  # Build tag file
  ( set -f; find -L "$SRC" $_CSCOPE_EXCLUDE -regextype posix-egrep -regex "$_CSCOPE_REGEX" -type f -execdir readlink -f "{}" \; |\
    command cscope $CSCOPE_OPTIONS -i '-' -f "$CSCOPE_DB" ) &&
      rm "${CSCOPE_DB}.in" "${CSCOPE_DB}.po" 2>/dev/null
}

# Make id-utils db
mkids() {
  command -v >/dev/null mkid || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  shift $(($#<=2?$#:2))
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
  shift $(($#<=2?$#:2))
  # Build tag file
  command pycscope -R -f "$DST/${_PYCSCOPE_OUT}" "$SRC"
}

# Make gtags files
mkgtags() {
  command -v >/dev/null gtags || return
  # Get directories, remove ~/
  local SRC="$(eval echo ${1:-$PWD})"
  local DST="$(eval echo ${2:-$PWD})"
  shift $(($#<=2?$#:2))
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
  rmcscope "$@"; mkcscope "$@"
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

# Make all tags recursively based on local config files
mkalltags() {
  local SRC="$(readlink -m "${1:-$PWD}")"
  export RC_DIR="${RC_DIR:-$HOME}"
  find -L "$SRC" -maxdepth ${2:-5} -type f -name ".*.path" -print0 2>/dev/null | xargs -r0 -- sh -c '
    . "$RC_DIR/.rc.d/14_tags.sh"
    for TAGPATH; do
      echo "** Processing file $TAGPATH"
      command cd "$(dirname $TAGPATH)" || continue
      TAGNAME="$(basename $TAGPATH)"
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".ctags.path" ]; then
        rmctags
        for SRC in $(cat "$TAGNAME"); do
          echo "[ctags] add: $SRC"
          mkctags "$SRC" . "-a"
        done
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".cscope.path" ]; then
        rmcscope
        for SRC in $(cat "$TAGNAME"); do
          echo "[cscope] add: $SRC"
          scancsdir "$SRC" .
        done
        mkcscope "$SRC" .
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".id.path" ]; then
        rmids
        for SRC in $(cat "$TAGNAME"); do
          echo "[id] add: $SRC"
          mkids "$SRC" .
        done
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".pycscope.path" ]; then
        rmpycscope
        for SRC in $(cat "$TAGNAME"); do
          echo "[pycscope] add: $SRC"
          mkpycscope "$SRC" .
        done
      fi
      echo "** Done."
    done
  ' _
}

