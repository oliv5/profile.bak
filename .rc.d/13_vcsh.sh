#!/bin/sh

# Repo vcsh-ready
vcsh_exists() {
  command git ${1:+--git-dir="$1"} config --get vcsh.vcsh >/dev/null 2>&1
}

# vcsh loaded
vcsh_loaded() {
  [ -n "$VCSH_REPO_NAME" ]
}

# vcsh init
vcsh_init() {
  local REPO="$1"
  shift 2>/dev/null
  vcsh init "$REPO" || return 1
  for ARGS; do
    set -- $ARGS
    vcsh run "$REPO" command git remote add "$@"
  done
}

# vcsh clone
vcsh_clone() {
  local URL="${1:?No URL specified}"
  local REMOTE="${2:-origin}"
  local BRANCH="${3:-master}"
  local REPO="$(basename "$URL" .git)"
  shift 3 2>/dev/null
  vcsh clone "$URL" "$REPO" || break
  vcsh run "$REPO" command git remote rename origin "$REMOTE"
  vcsh run "$REPO" command git checkout "$BRANCH"
  for ARGS; do
    set -- $ARGS
    vcsh run "$REPO" command git remote add "$@"
  done
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
