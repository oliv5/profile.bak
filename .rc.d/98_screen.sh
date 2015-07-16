#!/bin/sh
# Do not load when not installed
command -v screen >/dev/null || return 1

# Variables
#SCREEN_AUTOLOAD=""

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
screen_cmd() {
  local SESSION="${1:?No session specified...}"; shift $(min 1 $#)
  command -p screen -S "$SESSION" -X stuff "^C\n${@}\n"
}

# Set $DISPLAY
screen_setdisplay() {
  screen-cmd "$1" "export DISPLAY=$DISPLAY"
}

# List screen sessions
screen_list() {
  command -p screen -q -ls
  if [ $? -ne 9 ]; then
    screen -ls
  fi
}

# Alias
alias screen_recall='screen -r'
alias screen_restore='screen -R -D'
alias screen_quit='screen -X quit -S'
alias screen_killdetached="screen -ls | awk -F '.' '/Detached/{print \$1}' | xargs -r kill"
alias screen_killall="screen -ls | awk -F '.' '/pts/{print \$1}' | xargs -r kill"
alias screen_attach='reptyr'

# Re-attach session, or print the list
if [ ! -z "$SCREEN_AUTOLOAD" ] && [ -z "$ENV_LOADED" ] && shell_isinteractive && shell_islogin; then
  screen 2> /dev/null
else
  screen_list
fi

# End
return 0
