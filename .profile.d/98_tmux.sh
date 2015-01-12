#!/bin/sh

# Variables
TMUX_AUTOLOAD=""

# Wrapper function
function tmux() {
  if [ $# == 0 ]; then
    # Recall old session or create a new one
    command -p tmux attach -d || command -p tmux new-session
  else
    # Execute command normally
    command -p tmux "$@"
  fi
}

# Re-attach session, or print the list
if [[ ! -z "$TMUX_AUTOLOAD" && -z "$ENV_PROFILE_DONE" && $- == *i* ]] && shopt -q login_shell; then
  tmux
fi
