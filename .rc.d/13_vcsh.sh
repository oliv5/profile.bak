#!/bin/sh

# Repo vcsh-ready
vcsh_exists() {
  command git ${1:+--git-dir="$1"} config --get vcsh.vcsh >/dev/null 2>&1
}

# vcsh loaded
vcsh_loaded() {
  [ -n "$VCSH_REPO_NAME" ]
}

# vcsh run (including profile functions)
vcsh_run() {
  local REPO="$1"
  shift 2>/dev/null
  vcsh run "$REPO" sh -c '
    wrapper() { . $HOME/.rc; }; wrapper
    eval "$@"
  ' _ "$@"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#vcsh}" != "$1" ] && "$@" || true
