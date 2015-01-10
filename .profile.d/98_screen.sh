#!/bin/sh

# Variables
SCREEN_AUTOLOAD=""
export XDISPLAY="$DISPLAY"

# Alias
alias screen-list='screen -ls'
alias screen-restore='screen -R -D'
alias screen-killd='screen -ls | grep detached | cut -d. -f1 | awk '\''{print $1}'\'' | xargs -r kill'
alias screen-killa='screen -ls | grep pts | cut -d. -f1 | awk '\''{print $1}'\'' | xargs -r kill'

# Screen : re-attach session, or print the list
if [[ ! -z "$SCREEN_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- == *i* ]] && shopt -q login_shell && command -pv screen >/dev/null; then
  command -p screen -D -R
fi
