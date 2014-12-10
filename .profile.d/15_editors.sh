#!/bin/bash

#########################
# Gedit
function gedit() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  command -p gedit $ARGS
}

#########################
# Geany
function geany() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  command -p geany $ARGS
}

#########################
# Vim
export COLORTERM="xterm" # backspace bug in vim
[ -z "$VIM_USETABS" ] && export VIM_USETABS=""

# Start gvim
function gvim() {
  ARGS="$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g' <<< $@)"
  if [ -z "$VIM_USETABS" ]; then
    ARGS="${1:+--remote-silent} $ARGS"
  else
    ARGS="${1:+--remote-tab-silent} $ARGS"
  fi
  command -p gvim $ARGS
}

#########################
# Source insight
function si() {
  eval $(command -v si.sh || false) "$@"
}

#########################
# Export functions
export -f gedit
export -f geany
export -f gvim
export -f si
