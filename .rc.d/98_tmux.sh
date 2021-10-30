#!/bin/sh
# Do not load when not installed
if command -v tmux >/dev/null; then

# SSH autoload
if [ -z "$TMUX" -a -n "$SSH_CONNECTION" -a "${TMUX_AUTOLOAD#*ssh}" != "$TMUX_AUTOLOAD" ]; then
  TMUX_AUTOLOAD="yes"
fi

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
alias tmux_ls='tmux ls 2>/dev/null'
alias tmux_attach='reptyr'
alias tmux_kill='tmux kill-session'

# Re-attach session, or print the list
if [ -z "$TMUX" -a -z "$TMUX_LOADED" ]; then
  if [ "$TMUX_AUTOLOAD" = "yes" ] && shell_isinteractive && shell_islogin; then
    tmux 2>/dev/null
  fi
#else
#  tmux_ls
fi

# Flag
export TMUX_LOADED=1

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#tmux}" != "$1" ] && "$@" || true

fi
