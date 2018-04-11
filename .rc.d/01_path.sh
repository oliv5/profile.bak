#!/bin/sh

# Prepend to path
_path_prepend() {
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    #if [ -d "$DIR" ] && ! (eval echo "\$$VAR" | grep "${DIR}" >/dev/null); then
    if [ -d "$DIR" ]; then
      eval export $VAR="${DIR}\${$VAR:+:\$$VAR}"
    fi
  done
}

# Append to path
_path_append() {
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    #if [ -d "$DIR" ] && ! (eval echo "\$$VAR" | grep "${DIR}" >/dev/null); then
    if [ -d "$DIR" ]; then
      eval export $VAR="\${$VAR:+\$$VAR:}${DIR}"
    fi
  done
}

# Remove from path
_path_remove() {
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    eval export $VAR="$(eval echo "\$$VAR" | sed -r "s;${DIR}:?;;g")"
  done
}

# Remove given fs from path
_path_remove_fs() {
  local VAR="${1:-PATH}"
  local VAL="$(eval echo "\$$VAR")"
  local FS="${2:-cifs|fusefs|nfs}"
  local IFS=":"
  local RES
  for D in $VAL; do
    if ! stat -f -c %T "$D" 2>/dev/null | grep -Eq "$FS"; then
      RES="${RES:+$RES:}$D"
    fi
  done
  export $VAR="$RES"
}

# Remove absent path
_path_remove_absent() {
  local VAR="${1:-PATH}"
  local VAL="$(eval echo "\$$VAR")"
  local IFS=":"
  local RES
  for D in $VAL; do
    [ -d "$D" ] && RES="${RES:+$RES:}$D"
  done
  export $VAR="$RES"
}

# Cleanup path: remove duplicated or empty entries, expand $HOME
_path_cleanup() {
  local VAR="${1:-PATH}"
  shift
  #eval export $VAR="$(echo "\$$VAR" | awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':' | sed -r 's|~|'"${HOME}"'|g; s|\:\.||g; s|(^:\|:$)||')"
  export $VAR="$(
    str_uniq : : "$(eval echo "\$$VAR")" |
    awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':' |
    sed -r 's|~|'"${HOME}"'|g; s|\:\.||g; s|(^:\|:$)||')"
}

# Find and append path
_path_find() {
  local VAR="${1:-PATH}"
  local DIR="${2:-.}"
  local NAME="${3}"
  local RES="$(find "$DIR" ${NAME:+-name "$NAME"} -type d -print0 | xargs -r0 printf '%s')"
  export $VAR="$(eval echo "\$$VAR")${RES:+:$RES}"
}

# PATH aliases
path_prepend() { _path_prepend PATH "$@"; }
path_append() { _path_append PATH "$@"; }
path_remove() { _path_remove PATH "$@"; }
path_remove_fs() { _path_remove_fs PATH "$@"; }
path_remove_absent() { _path_remove_absent PATH "$@"; }
path_cleanup() { _path_cleanup PATH "$@"; }
path_find() { _path_find PATH "$@"; }
alias path_abs='readlink -f --'

# LD_LIBRARY_PATH aliases
# Warning: should not use it
# see ftp://linuxmafia.com/faq/Admin/ld-lib-path.html
ldlibpath_prepend() { _path_prepend LD_LIBRARY_PATH "$@"; }
ldlibpath_append() { _path_append LD_LIBRARY_PATH "$@"; }
ldlibpath_remove() { _path_remove LD_LIBRARY_PATH "$@"; }
ldlibpath_remove_fs() { _path_remove_fs LD_LIBRARY_PATH "$@"; }
ldlibpath_remove_absent() { _path_remove_absent LD_LIBRARY_PATH "$@"; }
ldlibpath_cleanup() { _path_cleanup LD_LIBRARY_PATH "$@"; }
ldlibpath_find() { _path_find LD_LIBRARY_PATH "$@"; }
