#!/bin/sh

#########################
# Default editors
[ -z "$EDITOR" ] && export EDITOR="$(command -v vim || command -v vi || command -v nano || command -v false)"
[ -z "$VISUAL" ] && export VISUAL="$EDITOR"
[ -z "$PAGER" ] && export PAGER="less -FX"
export LESS="-F" # Don't stop when less than 1 page

# Graphical editor
export GEDITOR="$(command -v geany || command -v gvim || command -v gedit || command -v false)"

#########################
# Gedit
if command -v gedit >/dev/null; then
  gedit() {
    local ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command gedit $ARGS
  }
fi

#########################
# Geany
if command -v geany >/dev/null; then
  geany() {
    local ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command geany $ARGS
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
    command gvim $ARGS
  }
fi

#########################
# Source insight
if command -v si.sh >/dev/null; then
  si() {
    PREFIX="$HOME/.wine-sourceinsight" si.sh "$@"
  }
fi
