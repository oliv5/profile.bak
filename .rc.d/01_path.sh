#!/bin/sh

# One realpath like implementation
command -v realpath >/dev/null ||
realpath() {
    python -c "import os.path; print os.path.relpath('$1', '${2:-$PWD}')"
}

# Prepend to path
_path_prepend() {
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    if [ -d "$DIR" ]; then
      eval trap "\"export $VAR='\${$VAR}'; trap - EXIT\"" EXIT
      eval export $VAR="${DIR}\${$VAR:+:\$$VAR}"
    fi
  done
  trap - EXIT
}

# Append to path
_path_append() {
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    if [ -d "$DIR" ]; then
      eval trap "\"export $VAR='\${$VAR}'; trap - EXIT\"" EXIT
      eval export $VAR="\${$VAR:+\$$VAR:}${DIR}"
    fi
  done
  trap - EXIT
}

# Remove from path
_path_remove() {
  command -v sed >/dev/null || return 1
  local VAR="${1:-PATH}"
  shift
  local DIR
  for DIR; do
    eval trap "\"export $VAR='\${$VAR}'; trap - EXIT\"" EXIT
    eval export $VAR="$(eval echo "\$$VAR" | sed -r "s;${DIR}:?;;g")"
  done
  trap - EXIT
}

# Remove given fs from path, as well as absent paths
_path_remove_fs() {
  command -v grep >/dev/null || return 1
  command -v stat >/dev/null || return 1
  local VAR="${1:-PATH}"
  local VAL="$(eval echo "\$$VAR")"
  local FS="${2:-cifs|fusefs|nfs}"
  local IFS=":"
  local RES=""
  for D in $VAL; do
    local CURFS="$(timeout 1s stat -f -c %T "$D" 2>/dev/null)"
    if [ $? -ne 0 ] || ! echo "$CURFS" | grep -Eq "$FS"; then
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
  local RES=""
  for D in $VAL; do
    [ -d "$D" ] && RES="${RES:+$RES:}$D"
  done
  export $VAR="$RES"
}

# Cleanup path: remove duplicated or empty entries, expand $HOME
_path_cleanup() {
  command -v awk >/dev/null || return 1
  command -v sed >/dev/null || return 1
  command -v cat >/dev/null || return 1
  command -v _str_uniq >/dev/null ||
    str_uniq() {
      local _IFS="${1:- }"
      local _OFS="${2}"
      shift 2
      printf '%s' "$@" | awk -vRS="$_IFS" -vORS="$_OFS" '!seen[$0]++ {str=str$1ORS} END{sub(ORS"$", "", str); printf "%s\n",str}'
    }
  local VAR="${1:-PATH}"
  shift
  eval trap "\"export $VAR='\${$VAR}'; trap - EXIT\"" EXIT
  export $VAR="$(
    { str_uniq : : "$(eval echo "\$$VAR")" || cat; } |
    { awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':' || cat; } |
    sed -r 's|~|'"${HOME}"'|g; s|\:\.||g; s|(^:\|:$)||')"
  trap - EXIT
}

# Find and append path
_path_find() {
  command -v find >/dev/null || return 1
  local VAR="${1:-PATH}"
  local DIR="${2:-.}"
  local NAME="${3}"
  local RES="$(find "$DIR" ${NAME:+-name "$NAME"} -type d -print0 | xargs -r0 printf '%s')"
  eval trap "\"export $VAR='\${$VAR}'; trap - EXIT\"" EXIT
  export $VAR="$(eval echo "\$$VAR")${RES:+:$RES}"
  trap - EXIT
}

# PATH aliases
path_prepend() { _path_prepend PATH "$@"; }
path_append() { _path_append PATH "$@"; }
path_remove() { _path_remove PATH "$@"; }
path_remove_fs() { _path_remove_fs PATH "$@"; }
path_remove_absent() { _path_remove_absent PATH "$@"; }
path_cleanup() { _path_cleanup PATH "$@"; }
path_find() { _path_find PATH "$@"; }
path_abs() { readlink -f -- "$@"; }
path_reset() { export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; }

# LD_LIBRARY_PATH aliases
# Warning: we should not use LD_LIBRARY_PATH
# see ftp://linuxmafia.com/faq/Admin/ld-lib-path.html
ldlibpath_prepend() { _path_prepend LD_LIBRARY_PATH "$@"; }
ldlibpath_append() { _path_append LD_LIBRARY_PATH "$@"; }
ldlibpath_remove() { _path_remove LD_LIBRARY_PATH "$@"; }
ldlibpath_remove_fs() { _path_remove_fs LD_LIBRARY_PATH "$@"; }
ldlibpath_remove_absent() { _path_remove_absent LD_LIBRARY_PATH "$@"; }
ldlibpath_cleanup() { _path_cleanup LD_LIBRARY_PATH "$@"; }
ldlibpath_find() { _path_find LD_LIBRARY_PATH "$@"; }
ldlibpath_reset() { export LD_LIBRARY_PATH=""; }
