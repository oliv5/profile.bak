#!/bin/sh
# Do not load when not installed
command -v tmux >/dev/null || return 1

# Variables
#TMUX_AUTOLOAD=""

# Wrapper function
tmux() {
  if [ $# = 0 ]; then
    # Recall old session or create a new one
    command -p tmux attach -d || command -p tmux new-session
  else
    # Execute command normally
    command -p tmux "$@"
  fi
}

#alias
alias tmux_list='tmux ls 2>/dev/null'
alias tmux_attach='reptyr'

# Re-attach session, or print the list
if [ ! -z "$TMUX_AUTOLOAD" ] && [ -z "$ENV_LOADED" ] && shell_isinteractive && shell_islogin; then
  tmux 2>/dev/null
else
  tmux ls 2>/dev/null
fi
