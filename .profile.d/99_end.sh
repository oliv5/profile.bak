#!/bin/sh

# Call local profile scripts
if [ -x ~/.localrc ]; then
  source ~/.localrc
fi
if [ -x ~/.profile.local ]; then
  source ~/.profile.local
fi
for i in $HOME/.profile.local.d/*.sh ; do
  if [ -x "$i" ]; then
    . "$i"
  fi
done

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"

# Export user functions
#fct-export-all

# Screen : re-attach session, or print the list
# see http://www.saltycrane.com/blog/2008/01/how-to-scroll-in-gnu-screen/
# [[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'
# shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'
if [[ $- == *i* ]] && shopt -q login_shell && command -pv screen >/dev/null; then
  command -p screen -D -R
  #command -p screen -list
  #echo "To reattach a session: screen -r <session>"
fi
