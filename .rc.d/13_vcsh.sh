#!/bin/sh

# Requirements
command -v arg_quote >/dev/null 2>&1 ||
arg_quote() {
  local SEP=''
  for ARG; do
    SQESC=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
    printf '%s' "${SEP}'${SQESC}'"
    SEP=' '
  done
}

# Repo vcsh-ready
vcsh_exists() {
  git ${1:+--git-dir="$1"} config --get vcsh.vcsh >/dev/null 2>&1
}

# vcsh loaded
vcsh_loaded() {
  [ ! -z "$VCSH_REPO_NAME" ]
}

# vcsh init
vcsh_init() {
  local REPO="$1"
  shift 2>/dev/null
  vcsh init "$REPO" || return 1
  for ARGS; do
    set -- $ARGS
    vcsh run "$REPO" git remote add "$@"
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
  vcsh run "$REPO" git remote rename origin "$REMOTE"
  vcsh run "$REPO" git checkout "$BRANCH"
  for ARGS; do
    set -- $ARGS
    vcsh run "$REPO" git remote add "$@"
  done
}

# Run a git command, call vcsh when necessary
vcsh_run() {
  if [ $# -le 1 ]; then
    local ARGS="$1"
  else    
    local ARGS="$(arg_quote "$@")"
  fi
  if vcsh_exists && ! vcsh_loaded; then
    vcsh run "$(git_repo)" sh -c "$ARGS"
  else
    sh -c "$ARGS"
  fi
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
