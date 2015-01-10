#!/bin/sh

# Variables
TMUX_AUTOLOAD=""

# Screen : re-attach session, or print the list
if [[ ! -z "$TMUX_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- == *i* ]] && shopt -q login_shell && command -pv tmux >/dev/null; then
  command -p tmux attach -d
fi
