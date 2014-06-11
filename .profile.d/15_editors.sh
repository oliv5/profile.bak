#!/bin/bash

#########################
# Gedit
export GEDIT="$(which gedit)"

function gedit() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  $GEDIT $ARGS
}

#########################
# Geany
export GEANY="$(which geany)"

function geany() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  $GEANY $ARGS
}

#########################
# Vim
export GVIM="$(which gvim)"
[ -z "$VIM_USETABS" ] && export VIM_USETABS=""
[ -z "$VIM_IDE" ] && export VIM_IDE=4
export COLORTERM="xterm" # backspace bug in vim

# Start gvim
function gvim() {
  ARGS="$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g' <<< $@)"
  if [ -z "$VIM_USETABS" ]; then
    $GVIM ${1:+--remote-silent} $ARGS
  else
    $GVIM ${1:+--remote-tab-silent} $ARGS
  fi
}

#########################
# Export functions
export -f gedit
export -f geany
export -f gvim

