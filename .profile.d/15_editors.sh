#!/bin/sh

#########################
# Gedit
if command -v gedit >/dev/null; then
  gedit() {
    ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command -p gedit $ARGS
  }
  export gedit
fi

#########################
# Geany
if command -v geany >/dev/null; then
  geany() {
    ARGS="$(echo $@ | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1 +\2/g')"
    command -p geany $ARGS
  }
  export geany
fi

#########################
# Vim
export COLORTERM="xterm" # backspace bug in vim
[ -z "$VIM_USETABS" ] && export VIM_USETABS=""

# Start gvim
if command -v gvim >/dev/null; then
  gvim() {
    ARGS="$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/+\2 \1/g' <<< $@)"
    if [ -z "$VIM_USETABS" ]; then
      ARGS="${1:+--remote-silent} $ARGS"
    else
      ARGS="${1:+--remote-tab-silent} $ARGS"
    fi
    command -p gvim $ARGS
  }
  export gvim
fi

#########################
# Source insight
if command -v si.sh >/dev/null; then
  si() {
    eval $(command -v si.sh || false) "$@"
  }
  export si
fi
