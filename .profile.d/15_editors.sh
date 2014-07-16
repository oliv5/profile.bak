#!/bin/bash

#########################
# Gedit
export GEDIT="$(which gedit 2>/dev/null)"

function gedit() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  ${GEDIT:-true} $ARGS
}

#########################
# Geany
export GEANY="$(which geany 2>/dev/null)"

function geany() {
  ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
  ${GEANY:-true} $ARGS
}

#########################
# Vim
export GVIM="$(which gvim 2>/dev/null)"
[ -z "$VIM_USETABS" ] && export VIM_USETABS=""
[ -z "$VIM_IDE" ] && export VIM_IDE=4
export COLORTERM="xterm" # backspace bug in vim

# Start gvim
function gvim() {
  ARGS="$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g' <<< $@)"
  if [ -z "$VIM_USETABS" ]; then
    ${GVIM:-true} ${1:+--remote-silent} $ARGS
  else
    ${GVIM:-true} ${1:+--remote-tab-silent} $ARGS
  fi
}

#########################
# Export functions
export -f gedit
export -f geany
export -f gvim

