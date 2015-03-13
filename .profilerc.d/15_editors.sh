#!/bin/sh

#########################
# Gedit
if command -v gedit >/dev/null; then
  gedit() {
    local ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command -p gedit $ARGS
  }
fi

#########################
# Geany
if command -v geany >/dev/null; then
  geany() {
    local ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command -p geany $ARGS
  }
fi

#########################
# Vim
export COLORTERM="xterm" # backspace bug in vim

# Start gvim
if command -v gvim >/dev/null; then
  gvim() {
    local ARGS="$(echo "$@" | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g')"
    if [ -z "$VIM_USETABS" ]; then
      ARGS="${1:+--remote-silent} $ARGS"
    else
      ARGS="${1:+--remote-tab-silent} $ARGS"
    fi
    command -p gvim $ARGS
  }
fi

#########################
# Source insight
if command -v si.sh >/dev/null; then
  si() {
    PREFIX="$HOME/.wine-sourceinsight" si.sh "$@"
  }
fi
