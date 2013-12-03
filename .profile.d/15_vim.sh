#!/bin/bash

# Vim
export GVIM="$(which gvim)"
[ -z "$VIM_USETABS" ] && export VIM_USETABS=""
[ -z "$VIM_IDE" ] && export VIM_IDE=4

# Terminal settings
export COLORTERM="xterm" # backspace bug in vim

# Start gvim
function gvim() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g')"
  if [ -z "$VIM_USETABS" ]; then
    $GVIM ${1:+--remote-silent} $ARGS
  else
    $GVIM ${1:+--remote-tab-silent} $ARGS
  fi
}
export -f gvim
