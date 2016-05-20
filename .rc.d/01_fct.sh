#!/bin/sh

################################
# Check fct exists
fct_exists() {
  true ${1:?No fct specified}
  set | grep -G "^$1\s*()" >/dev/null 2>&1
  # The following code returns false when
  # function is overriden by an existing alias
  #[ "$(type -t $1)" = "function" ]
}

# Get fct definition
fct_def() {
  true ${1:?No fct specified}
  if fct_exists "$1"; then
    type $1 | tail -n +2
  fi
}

# Get fct content
fct_content() {
  true ${1:?No fct specified}
  if fct_exists "$1"; then
    type $1 | head -n -1 | tail -n +4
  fi
}

# Append to fct
fct_append() {
  local FCT=${1:?No fct specified}; shift
  eval "${FCT}() { $(fct_content $FCT); $@; }"
}

# Preppend to fct
fct_prepend() {
  local FCT=${1:?No fct specified}; shift
  eval "${FCT}() { $@; $(fct_content $FCT); }"
}

# Check alias/fct collision
fct_collision() {
  for ALIAS in $(alias | awk -F '[= ]' '{print $2}'); do
    [ "${1:-$ALIAS}" = "$ALIAS" ] &&
    fct_exists "$ALIAS" && 
    echo "$ALIAS"
  done
}
