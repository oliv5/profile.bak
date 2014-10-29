#!/bin/bash

#########################
# Gedit
export GEDIT="$(which gedit)"

function gedit() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  eval ${GEDIT:-false} $ARGS
}

#########################
# Geany
export GEANY="$(which geany)"

function geany() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  eval ${GEANY:-false} $ARGS
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
    eval ${GVIM:-false} ${1:+--remote-silent} $ARGS
  else
    eval ${GVIM:-false} ${1:+--remote-tab-silent} $ARGS
  fi
}

#########################
# Source insight
export SI="$(which si.sh)"

function si() {
  eval ${SI:-false} "$@"
}

#########################
# Export functions
export -f gedit
export -f geany
export -f gvim
export -f si
