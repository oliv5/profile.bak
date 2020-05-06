#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts

# Ctags settings
_CTAGS_OPTS='--fields=+iaS --extra=+qf --c++-kinds=+p --python-kinds=-i'
_CTAGS_REGEX='.*\.(h|c|cc|cpp|hpp|inc|py|S)$'
_CTAGS_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
_CTAGS_OUT='.tags'

# Cscope settings
_CSCOPE_OPTS='-qbk'
_CSCOPE_REGEX='.*\.(h|c|cc|cpp|hpp|inc|py|S)$'
_CSCOPE_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
_CSCOPE_OUT='.cscope.out'

# ID-utils settings
_MKID_OPTS=''
_MKID_REGEX='.*\.(h|c|cc|cpp|hpp|inc|py|S)$'
_MKID_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
_MKID_OUT='.id'

# pycscope settings
_PYCSCOPE_OPTS=''
_PYCSCOPE_REGEX='.*\.py$'
_PYCSCOPE_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
_PYCSCOPE_OUT='.pycscope.out'

# gtags settings
_GTAGS_OPTS=''
_GTAGS_REGEX='.*\.(h|c|cc|cpp|hpp|inc|py|S)$'
_GTAGS_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'

# Scan for files either from a filelist, a repository or fallback to a bare recursive file scan
_scandir() {
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local MATCHING="${2:-.*}"
  local EXCLUDING="${3:--not -path '*.svn*' -and -not -path '*.git' -and -not -path '/tmp/*'}"
  shift $(($#<=3?$#:3))
  if [ -f "$SRC" ]; then
    cat "$SRC"
  elif git_exists "$SRC/.git"; then
    git --git-dir="$SRC/.git" ls-files -z
  elif svn_exists "$SRC"; then
    svn ls "$SRC" | tr '\n' '\0'
  else
    find -L "$SRC" $EXCLUDING -regextype posix-egrep -regex "$MATCHING" -type f -print0 | xargs -r0 readlink -ze
  fi
}

# Make ctags db
mkctags() {
  command -v >/dev/null ctags || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local DB="${DST}/${_CTAGS_OUT}"
  shift $(($#<=2?$#:2))
  # Build tag file
  _scandir "$SRC" "$_CTAGS_REGEX" "$_CTAGS_EXCLUDE" |
    xargs -r0 ctags $_CTAGS_OPTS $* -f "${DB}"
  ln -fs "${DB}" "${DST}/tags"
}

# Make cscope db
mkcscope() {
  command -v >/dev/null cscope || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local DB="$DST/${_CSCOPE_OUT}"
  shift $(($#<=2?$#:2))
  # Build tag file
  _scandir "$SRC" "$_CSCOPE_REGEX" "$_CSCOPE_EXCLUDE" |
    xargs -r0 cscope $_CSCOPE_OPTS $* -f "$DB" &&
      rm "${DB}.in" "${DB}.po" 2>/dev/null
}

# Make id-utils db
mkids() {
  command -v >/dev/null mkid || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local DB="$DST/${_MKID_OUT}"
  shift $(($#<=2?$#:2))
  # Build tag file
  _scandir "$SRC" "$_MKID_REGEX" "$_MKID_EXCLUDE" |
    xargs -r0 mkid $_MKID_OPTS $* -o "$DB"
}

# Make pycscope db
mkpycscope() {
  command -v >/dev/null pycscope || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local DB="$DST/${_PYCSCOPE_OUT}"
  shift $(($#<=2?$#:2))
  # Build tag file
  _scandir "$SRC" "$_PYCSCOPE_REGEX" "$_PYCSCOPE_EXCLUDE" |
    xargs -r0 pycscope $_PYCSCOPE_OPTS $* -f "$DB"
}

# Make gtags files
mkgtags() {
  command -v >/dev/null gtags || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  shift $(($#<=2?$#:2))
  # Build tag files
  _scandir "$SRC" "$_GTAGS_REGEX" "$_GTAGS_EXCLUDE" |
    xargs -r0 -n1 | gtags $_GTAGS_OPTS $* -f - "$DST"
}

# Make all tags
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
  rm -v "${DIR}/${_CSCOPE_OUT}"* 2>/dev/null
}

# Clean id-utils db
rmids() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_MKID_OUT}" 2>/dev/null
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

# Clean all tags
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
    . "$RC_DIR/.rc.d"/*_tags.sh
    for TAGPATH; do
      echo "** Processing file $TAGPATH"
      command cd "$(dirname $TAGPATH)" || continue
      TAGNAME="$(basename $TAGPATH)"
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".ctags.path" ]; then
        rmctags
        for SRC in $(cat "$TAGNAME"); do
          echo "[ctags] add: $SRC"
          mkctags "$SRC" . --append
        done
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".cscope.path" ]; then
        rmcscope
        echo -n > .tagfilelist
        for SRC in $(cat "$TAGNAME"); do
          echo "[cscope] add: $SRC"
          _scandir "$SRC" "$_CSCOPE_REGEX" "$_CSCOPE_EXCLUDE" >> .tagfilelist
        done
        mkcscope .tagfilelist .
        rm .tagfilelist
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".id.path" ]; then
        rmids
        echo -n > .tagfilelist
        for SRC in $(cat "$TAGNAME"); do
          echo "[id] add: $SRC"
          _scandir "$SRC" "$_MKID_REGEX" "$_MKID_EXCLUDE" >> .tagfilelist
        done
        mkids .tagfilelist .
        rm .tagfilelist
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".pycscope.path" ]; then
        rmpycscope
        echo -n > .tagfilelist
        for SRC in $(cat "$TAGNAME"); do
          echo "[pycscope] add: $SRC"
          _scandir "$SRC" "$_PYCSCOPE_REGEX" "$_PYCSCOPE_EXCLUDE" >> .tagfilelist
        done
        mkpycscope .tagfilelist .
        rm .tagfilelist
      fi
      if [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".gtags.path" ]; then
        rmgtags
        for SRC in $(cat "$TAGNAME"); do
          echo "[gtags] add: $SRC"
          mkgtags "$SRC" . -i
        done
      fi
      echo "** Done."
    done
  ' _
}

