#!/bin/bash

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE_D=$ENV_CNT

################################
# Language selection functions
function lang_fr() {
  export LANGUAGE="fr:en"
  export LC_ALL="fr_FR.UTF-8"
}
function lang_en() {
  unset LANGUAGE
  export LC_ALL="en_US.UTF-8"
}

################################
# Call stack
function print-callstack() {
  # skipping i=0 as this is print_call_trace itself
  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    echo -n  ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}:${FUNCNAME[$i]}"(): "
    sed -n "${BASH_LINENO[$i-1]}p" $0
  done
}

################################
# Set error handler
function trap-map() {
  trap 'die "Error handler:" 1 ${LINENO}' ${@:-1 15} ERR
}

# Die function
function die () {
  printf '%s%s\n' "${3:+(line $3) }" "${1:-Unknown error. abort...}"
  [[ $- == *i* ]] && return ${2:-1} || exit ${2:-1}
}

################################
# List user functions
function fct-ls() {
  declare -F | cut -d" " -f3 | egrep -v "^_"
}

# Export user functions from script
function fct-export() {
  export -f "$@"
}

# Remove function
function fct-unset() {
  unset -f "$@"
}

# Export all user functions
function fct-export-all() {
  export -f $(fct-ls)
}

# Print fct content
function fct-content() {
  type ${1:?No fct name given...} 2>/dev/null | tail -n+4 | head -n-1
}

################################
# Get script directory
function pwd-get() {
  echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
}

################################
# Cmd exist test
function cmd-exists() {
  command -v ${1} >/dev/null
}

# Cmd unset
function cmd-unset() {
  unalias $* 2>/dev/null
  unset -f $* 2>/dev/null
}

# Remove some aliases/fct shortcuts
cmd-unset which grep find

################################
# Start ssh-agent when not already running
pgrep -u $USER ssh-agent >/dev/null || eval $(ssh-agent)

