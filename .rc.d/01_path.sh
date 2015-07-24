#!/bin/sh
# Script dependencies
rc_sourcemod "shell fct"

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
    eval export $VAR="$(eval echo "\$$VAR" | sed -e "s;${DIR}:\?;;g")"
  done
}

# Cleanup path
_path_cleanup() {
  local VAR="${1:-PATH}"
  shift
  #eval export $VAR="$(echo "\$$VAR" | awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':' | sed -r 's|~|'"${HOME}"'|g; s|\:\.||g; s|(^:\|:$)||')"
  export $VAR="$(
    str_uniq : : "$(eval echo "\$$VAR")" | 
    awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':' | 
    sed -r 's|~|'"${HOME}"'|g; s|\:\.||g; s|(^:\|:$)||')"
}

# Add to PATH
alias path_prepend='_path_prepend PATH'
alias path_append='_path_append PATH'
alias path_remove='_path_remove PATH'
alias path_cleanup='_path_cleanup PATH'
alias path_abs='readlink -f --'

# Add to LD_LIBRARY_PATH
# Warning: should not use it
# see ftp://linuxmafia.com/faq/Admin/ld-lib-path.html
alias ldlibpath_prepend='_path_prepend LD_LIBRARY_PATH'
alias ldlibpath_append='_path_append LD_LIBRARY_PATH'
alias ldlibpath_remove='_path_remove LD_LIBRARY_PATH'
alias ldlibpath_cleanup='_path_cleanup LD_LIBRARY_PATH'
