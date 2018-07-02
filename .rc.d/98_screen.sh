#!/bin/sh
# Do not load when not installed
command -v screen >/dev/null || return 0

# SSH autoload
if [ -z "$STY" -a -n "$SSH_CONNECTION" -a "${SCREEN_AUTOLOAD#*ssh}" != "$SCREEN_AUTOLOAD" ]; then
  SCREEN_AUTOLOAD="yes"
fi

# Wrapper function
screen() {
  [ -z "$SCREEN_DISPLAY" ] && export SCREEN_DISPLAY="$DISPLAY"
  if [ $# = 0 ]; then
    # Recall old session or create a new one
    command -p screen -R
  else
    # Execute command normally
    command -p screen "$@"
  fi
}

# Send a command to a running screen
screen_send() {
  local SESSION="${1:?No session specified...}"; shift $(min 1 $#)
  command -p screen -S "$SESSION" -X stuff "^C\n${@}\n"
}

# Set $DISPLAY
screen_setdisplay() {
  screen_send "$1" "export DISPLAY=$DISPLAY"
}

# List screen sessions
screen_ls() {
  command -p screen -q -ls
  if [ $? -ne 9 ]; then
    screen -ls
  fi
}

# Long aliases
alias screen_recall='screen -r'
alias screen_restore='screen -R -D'
alias screen_quit='screen -X quit -S'
alias screen_killdetached="screen -ls | awk -F '.' '/Detached/{print \$1}' | xargs -r kill"
alias screen_killall="screen -ls | awk -F '.' '/pts/{print \$1}' | xargs -r kill"
alias screen_clean='screen -wipe'
alias screen_attach='reptyr'
alias screen_fork='screen -d -m'

# Short aliases
alias scls='screen_ls'
alias scr='screen_restore'
alias sck='screen_quit'

# Re-attach session, or print the list
if [ -z "$STY" -a -z "$SCREEN_LOADED" ]; then
  if [ "$SCREEN_AUTOLOAD" = "yes" ] && shell_isinteractive && shell_islogin; then
    screen 2> /dev/null
  fi
#else
#  screen_ls
fi

# Flag
export SCREEN_LOADED=1

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#screen}" != "$1" ] && "$@" || true
