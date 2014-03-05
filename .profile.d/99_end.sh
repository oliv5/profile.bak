#!/bin/sh

# Call local profile scripts
if [ -f ~/.profile.local ]; then
  source ~/.profile.local
fi
for i in $HOME/.profile.local.d/*.sh ; do
  if [ -x "$i" ]; then
    . "$i"
  fi
done

# Export user functions
#fct-export
export -f die
