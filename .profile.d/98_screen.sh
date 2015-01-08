#!/bin/sh

# Alias
alias screen-list='screen -ls'
alias screen-kill="screen -ls | grep detached | cut -d. -f1 | awk '{print $1}' | xargs kill"
alias screen-killall="screen -ls | grep pts | cut -d. -f1 | awk '{print $1}' | xargs kill"

# Screen : re-attach session, or print the list
# see http://www.saltycrane.com/blog/2008/01/how-to-scroll-in-gnu-screen/
# [[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'
# shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'
if [[ $- == *i* ]] && shopt -q login_shell && command -pv screen >/dev/null; then
  command -p screen -D -R
  #command -p screen -list
  #echo "To reattach a session: screen -r <session>"
fi
