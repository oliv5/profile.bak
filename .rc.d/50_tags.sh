#!/bin/sh
# Note: this file must be independant, it can be sourced by external scripts
# Note: don't use "$@" in this main script, it will be filled with paths when mkalltags() is called
RC_DIR="${RC_DIR:-$HOME}"
if ! command -v git_exists >/dev/null; then
  . "$RC_DIR/.rc.d"/*_git.sh
fi
if ! command -v snv_exists >/dev/null; then
  . "$RC_DIR/.rc.d"/*_svn.sh
fi

# Ctags settings
# Currently using Exuberant Ctags 5.9~svn20110310
_CTAGS_OPTS='--append --fields=+iaS --extra=+qf --c-types=+l --c++-kinds=+p --python-kinds=-i'
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

# Starscope settings
_STARSCOPE_OPTS='-e cscope'
_STARSCOPE_REGEX='.*\.(js|go|rb)$'
_STARSCOPE_EXCLUDE='-not -path "*.svn*" -and -not -path "*.git" -and -not -path "/tmp/*"'
_STARSCOPE_OUT='.starscope.db'

# Scan for files either from a git/svn repository or fallback to a bare recursive file scan
# File paths are zero terminated (NUL)
_tags_scandir() {
  local SRC="$(readlink -e "${1:-$PWD}")" # also removes ~/
  local MATCHING="${2:-.*}"
  if [ ! -e "$SRC" ]; then
    return
  elif [ -f "$SRC" ]; then
    # Special list of file ?
    if [ "$(head -n 1 "$SRC" | cut -c -23)" = "## rc tags file list ##" ]; then
      tail -n +2 "$SRC"
    else
      printf "$SRC\0"
    fi
  else
    {
      ( command cd "$SRC" 2>/dev/null && git ls-files --exclude-standard -z 2>/dev/null ) | grep -zZE "$MATCHING" | xargs -r0 sh -c "for P; do printf \"$SRC/%s\0\" \"\$P\"; done; exit 1" _
      if [ $? -ne 123 ]; then
        svn ls "$SRC" 2>/dev/null | grep -E "$MATCHING" | xargs -r sh -c "for P; do printf \"$SRC/%s\0\" \"\$P\"; done; exit 1" _
        if [ $? -ne 123 ]; then
          local EXCLUDING="${3:--not -path '*.svn*' -and -not -path '*.git' -and -not -path '/tmp/*'}"
          find -L "$SRC" $EXCLUDING -regextype posix-egrep -regex "$MATCHING" -type f -print0 2>/dev/null | xargs -r0 readlink -ze
        fi
      fi
    } | 
      # Check readlink -z is supported (when not supported, it does not support multiple input files neither !!??)
      if readlink -z / >/dev/null 2>&1; then cat - | xargs -r0 readlink -ze; else cat - | xargs -r0 -n1 readlink -e | tr '\n' '\0'; fi
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
  _tags_scandir "$SRC" "$_CTAGS_REGEX" "$_CTAGS_EXCLUDE" |
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
  _tags_scandir "$SRC" "$_CSCOPE_REGEX" "$_CSCOPE_EXCLUDE" |
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
  _tags_scandir "$SRC" "$_MKID_REGEX" "$_MKID_EXCLUDE" |
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
  _tags_scandir "$SRC" "$_PYCSCOPE_REGEX" "$_PYCSCOPE_EXCLUDE" |
    xargs -r0 pycscope $_PYCSCOPE_OPTS $* -f "$DB"
}

# Make gtags files
mkgtags() {
  command -v >/dev/null gtags || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  shift $(($#<=2?$#:2))
  # Build tag files
  _tags_scandir "$SRC" "$_GTAGS_REGEX" "$_GTAGS_EXCLUDE" |
    xargs -r0 -n1 | gtags $_GTAGS_OPTS $* -f - "$DST"
}

# Make starscope db
mkstarscope() {
  command -v >/dev/null starscope || return
  local SRC="$(eval echo ${1:-$PWD})" # Remove ~/
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local DB="$DST/${_STARSCOPE_OUT}"
  shift $(($#<=2?$#:2))
  # Build tag file
  _tags_scandir "$SRC" "$_STARSCOPE_REGEX" "$_STARSCOPE_EXCLUDE" |
    xargs -r0 starscope $_STARSCOPE_OPTS $* -f "$DB"
}

# General purpose: make incremental tag db
mkinc() {
  local FCT="${1:?No tag make function defined...}"
  local DST="$(eval echo ${2:-$PWD})" # Remove ~/
  local REGEX="$3"
  local EXCLUDE="$4"
  shift $(($#<=4?$#:4))
  echo -n "" > .tags_tmp
  for SRC in "${@:-.}"; do
    _tags_scandir "$SRC" "$REGEX" "$EXCLUDE" >> .tags_tmp
  done
  # tag file list is a marker + \n + list of files with \0
  echo "## rc tags file list ##" > .tags_files
  sort -z -u .tags_tmp >> .tags_files
  $FCT .tags_files "$DST"
  rm .tags_tmp .tags_files
}

# Make all tags
mktags() {
  mkctags "$@"
  mkgtags "$@"
  mkcscope "$@"
  mkids "$@"
  mkpycscope "$@"
  mkstarscope "$@"
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

# Clean starscope db
rmstarscope() {
  # Get directories, remove ~/
  local DIR="$(eval echo ${1:-$PWD})"
  rm -v "${DIR}/${_STARSCOPE_OUT}" 2>/dev/null
}

# Clean all tags
rmtags() {
  rmctags "$@"
  rmgtags "$@"
  rmcscope "$@"
  rmids "$@"
  rmpycscope "$@"
  rmstarscope "$@"
}

# Make all tags recursively in folders where .path files are,
mkalltags() {
  local SRC="$(readlink -m "${1:-$PWD}")"
  local MAXDEPTH="${2:-5}"
  local TAGTYPES="${3:-ctags cscope mkid pycscope gtags starscope}"
  find -L "$SRC" -maxdepth "$MAXDEPTH" -type f -name ".*.path" -print0 2>/dev/null | xargs -r0 -- sh -c '
    RC_DIR="$1"; TAGTYPES="$2"; shift 2
    . "$RC_DIR/.rc.d"/*_tags.sh
    tag_selected() { echo " $TAGTYPES " | grep -F " $1 " >/dev/null && [ "$TAGNAME" = ".tags.path" -o "$TAGNAME" = ".${2}.path" ]; }
    for TAGPATH; do
      echo "** Processing file $TAGPATH"
      command cd "$(dirname $TAGPATH)" || continue
      TAGNAME="$(basename $TAGPATH)"
      if tag_selected ctags ctags; then
        rmctags .
        cat "$TAGNAME" | xargs -r echo "[ctags] add:"
        mkinc mkctags . "$_CTAGS_REGEX" "$_CTAGS_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      if tag_selected cscope cscope; then
        rmcscope .
        cat "$TAGNAME" | xargs -r echo "[cscope] add:"
        mkinc mkcscope . "$_CSCOPE_REGEX" "$_CSCOPE_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      if tag_selected mkid id; then
        rmids .
        cat "$TAGNAME" | xargs -r echo "[mkid] add:"
        mkinc mkids . "$_MKID_REGEX" "$_MKID_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      if tag_selected pycscope pycscope; then
        rmpycscope .
        cat "$TAGNAME" | xargs -r echo "[pycscope] add:"
        mkinc mkpycscope . "$_PYCSCOPE_REGEX" "$_PYCSCOPE_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      if tag_selected gtags gtags; then
        rmgtags .
        cat "$TAGNAME" | xargs -r echo "[gtags] add:"
        mkinc mkgtags . "$_GTAGS_REGEX" "$_GTAGS_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      if tag_selected starscope starscope; then
        rmstarscope .
        cat "$TAGNAME" | xargs -r echo "[starscope] add:"
        mkinc mkstarscope . "$_STARSCOPE_REGEX" "$_STARSCOPE_EXCLUDE" $(cat "$TAGNAME" | xargs -r)
      fi
      echo "** Done."
    done
  ' _ "$RC_DIR" "$TAGTYPES"
}

# Note: don't use "$@" in this main script, it will be filled with paths when mkalltags() is called
# END
