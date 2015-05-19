#!/bin/sh

################################
# Get fct definition
fct_def() {
  true ${1:?No fct specified}
  if [ "$(type -t ${1:?No fct specified})" = "function" ]; then
    type $1 | tail -n +2
  fi
}

# Get fct content
fct_content() {
  true ${1:?No fct specified}
  if [ "$(type -t $1)" = "function" ]; then
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

################################
# Misc utils (used for shifts)
min() { echo $(($1<$2?$1:$2)); }
max() { echo $(($1>$2?$1:$2)); }
lim() { max $(min $1 $3) $2; }
isint() { expr 2 "*" "$1" + 1 >/dev/null 2>&1; }

################################
# Run a command and filter stdout by another one
filter_stdout() {
  { eval "$1" 2>&1 1>&3 | eval "$2" 1>&2; } 3>&1
}
