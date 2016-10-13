#!/bin/sh

#########################
# Default editors
[ -z "$EDITOR" ] && export EDITOR="$(command -v vi -e || command -v false)"
[ -z "$VISUAL" ] && export VISUAL="$(command -v vim || command -v vi || command -v nano || command -v false)"
[ -z "$PAGER" ] && export PAGER="less -FXr"
export LESS="-FXr" # Don't stop when less than 1 page, color

# Graphical editor
export GEDITOR="$(command -v geany || command -v gvim || command -v gedit || command -v false)"

#########################
# Gedit
if command -v gedit >/dev/null; then
  gedit() {
    local ARGS="$(echo $@ | sed -re 's/([^ :]*):([0-9]*)(:[^ ]*)?/+\2 \1/g')"
    command gedit $ARGS
  }
fi

#########################
# Geany
if command -v geany >/dev/null; then
  geany() {
    local ARGS="$(echo $@ | sed -re 's/([^ :]*):([0-9]*)(:[^ ]*)?/+\2 \1/g')"
    command geany $ARGS
  }
fi

#########################
# Vim
export COLORTERM="xterm" # backspace bug in vim

# Start gvim
if command -v gvim >/dev/null; then
  gvim() {
    local ARGS="$(echo $@ | sed -re 's/([^ :]*):([0-9]*)(:[^ ]*)?/+\2 \1/g')"
    ARGS="${1:+--remote-${VIM_USETABS:+tab-}silent} $ARGS"
    [ "$1" == "-" ] && ARGS="-"
    command gvim $ARGS
  }
fi

#########################
# Source insight
alias si='PREFIX="$HOME/.wine-sourceinsight" si.sh'
alias si2='PREFIX="$HOME/.wine-sourceinsight2" si.sh'
alias si3='PREFIX="$HOME/.wine-sourceinsight3" si.sh'
