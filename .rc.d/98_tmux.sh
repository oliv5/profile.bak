#!/bin/sh
# Do not load when not installed
command -v tmux >/dev/null || return 1

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

# Re-attach session, or print the list
if [ -z "$TMUX" -a -z "$ENV_RC_END" ]; then
  if [ "$TMUX_AUTOLOAD" = "yes" ] && shell_isinteractive && shell_islogin; then
    tmux 2>/dev/null
  fi
#else
#  tmux_ls
fi
