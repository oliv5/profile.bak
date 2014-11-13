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

# Export user functions
#fct-export-all

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"
