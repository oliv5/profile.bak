#!/bin/sh

#########################
# Default editors
[ -z "$EDITOR" ] && export EDITOR="$(command -v vi -e || command -v false)"
[ -z "$VISUAL" ] && export VISUAL="$(command -v vim || command -v vi || command -v nano || command -v false)"
[ -z "$PAGER" ] && export PAGER="less -FXr"
export LESS="-FXr" # Don't stop when less than 1 page, color
export GEDITOR="$(command -v geany || command -v gvim || command -v gedit || command -v false)"

#########################
# Gedit
if command -v gedit >/dev/null; then
  gedit() {
    local ARGS="$(echo $@ | sed -re 's/([^ :]*):?([0-9]*)?(:[^ ]*)?/+\2 \1/g')"
    command gedit $ARGS
  }
fi

#########################
# Geany
if command -v geany >/dev/null; then
  geany() {
    local ARGS="$(echo $@ | sed -re 's/([^ :]*):?([0-9]*)?(:[^ ]*)?/+\2 \1/g')"
    command geany $ARGS
  }
fi

#########################
# Vim
export COLORTERM="xterm" # backspace bug in vim
export VI="$(command -v vim || command -v vi)"
unset VIM # bug at startup if defined

# Start gvim
if command -v gvim >/dev/null; then
  export VI="gvim"
  gvim() {
    local ARGS=""
    local ARG1="$1"
    if [ -n "$ARG1" -a "$ARG1" != "-" ]; then
      ARG1="$(echo "$ARG1" | awk -F':' '{printf "+%s \"%s\"",$2,$1}')"
      ARG1="${ARG1:+--remote-${VIM_USETABS:+tab-}silent }$ARG1"
    fi
    shift
    for ARG; do
      if [ "$ARG" != "-" ]; then
        ARG="$(echo "$ARG" | awk -F':' '{printf "\"%s\"",$1}')"
      fi
      ARGS="${ARGS:+$ARGS }$ARG"
    done
    eval command gvim $ARG1 $ARGS
  }
fi

#########################
# Source insight via wine
if command -v wine >/dev/null; then
  sourceinsight() {
    local WINEPREFIX="${WINEPREFIX:-$HOME/.wineprefix/sourceinsight}"
    local DIR="$WINEPREFIX/drive_c/Program Files (x86)/Source Insight 3"
    if [ ! -d "$DIR" ]; then
      DIR="$WINEPREFIX/drive_c/Program Files/Source Insight 3"
    fi
    WINEPREFIX="$WINEPREFIX" wine "$DIR/Insight3.exe" "$@" 2>/dev/null &
  }
fi

#########################
# File manager
if [ -z "$FMANAGER" ];then
  export FMANAGER="$(command -v nautilus || command -v konqueror || command -v dolphin || command -v gnome-commander)"
fi
