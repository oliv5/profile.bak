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
  for FCT; do
    if fct_exists "$FCT"; then
      type $1 | tail -n +2
    fi
  done
}
fct_def_tiny() {
  fct_def "$@" | tr '\n' ';' | sed -e 's/()\s*;/()/' -e 's/{\s*;/{ /' -e 's/{\s*/{ /' -e 's/;}/; }/' -e 's/;$//'
}

# Get fct content
fct_content() {
  for FCT; do
    if fct_exists "$FCT"; then
      type $1 | head -n -1 | tail -n +4
    fi
  done
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

# Wrap script fcts in aliases
# Useful ?
fct_wrap() {
  for SCRIPT; do
    SCRIPT="$(readlink -f "$SCRIPT")"
    while IFS= read -r FCT; do 
      alias $FCT="(unalias -a; . $SCRIPT; eval $FCT)"
    done <<EOF
$(awk -F '(' '/^.*_.*\s*\(\)\s*\{?$/ {print $1}' "$SCRIPT")
EOF
  done
}
