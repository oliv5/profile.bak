#!/bin/sh

# Variables
#SCREEN_AUTOLOAD=""

# Wrapper function
screen() {
  [ -z "$SCREEN_DISPLAY" ] && export SCREEN_DISPLAY="$DISPLAY"
  if [ $# = 0 ]; then
    # Recall old session or create a new one
    command -p screen -d -R
  else
    # Execute command normally
    command -p screen "$@"
  fi
}

# Send a command to a running screen
screen-cmd() {
  command -p screen -S ${1:?No session specified...} -X stuff "${@:2}"
}

# Alias
alias screen-list='screen -ls'
alias screen-restore='screen -R -D'
alias screen-killd="screen -ls | awk -F "." '/Detached/{print $1}' | xargs -r kill"
alias screen-killa="screen -ls | awk -F "." '/pts/{print $1}' | xargs -r kill"

# Re-attach session, or print the list
if [[ ! -z "$SCREEN_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- = *i* ]] && shopt -q login_shell; then
  screen 2> /dev/null
fi
