#!/bin/sh

# Variables
#SCREEN_AUTOLOAD=""
export SCREEN_DISPLAY="$DISPLAY"

# Wrapper function
function screen() {
  export SCREEN_DISPLAY="$DISPLAY"
  if [ $# == 0 ]; then
    # Recall old session or create a new one
    command -p screen -D -R
  else
    # Execute command normally
    command -p screen "$@"
  fi
}

# Alias
alias screen-list='screen -ls'
alias screen-restore='screen -R -D'
alias screen-killd='screen -ls | grep detached | cut -d. -f1 | awk '\''{print $1}'\'' | xargs -r kill'
alias screen-killa='screen -ls | grep pts | cut -d. -f1 | awk '\''{print $1}'\'' | xargs -r kill'

# Re-attach session, or print the list
if [[ ! -z "$SCREEN_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- == *i* ]] && shopt -q login_shell; then
  screen
fi
