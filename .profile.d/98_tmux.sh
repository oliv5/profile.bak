#!/bin/sh

# Variables
TMUX_AUTOLOAD=1
TMUX="$(command -pv tmux)"

# Screen : re-attach session, or print the list
if [[ ! -z "$TMUX_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- == *i* ]] && shopt -q login_shell; then
  command -pv tmux 2>/dev/null && (command -p tmux attach -d || command -p tmux new-session)
fi
