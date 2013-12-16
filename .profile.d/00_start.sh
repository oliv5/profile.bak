#!/bin/bash

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE_D=$ENV_CNT

# Call env external profile script
if [ -x ~/.localsrc ]; then
  source ~/.localsrc
fi

# Add to path function
function addpath() {
  for DIR in "$@"; do
    if ! [[ $PATH =~ $DIR ]]; then
      export PATH="$PATH:$DIR"
    fi
  done
}

# Call stack
function print-calltrace()
{
  # skipping i=0 as this is print_call_trace itself
  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    echo -n  ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}:${FUNCNAME[$i]}"(): "
    sed -n "${BASH_LINENO[$i-1]}p" $0
  done
}

# Set error handler
function map-errorhandler() {
  trap 'die "Error handler:" -1 ${LINENO}' ${@:-1 15} ERR
}

# Die function
function die () {
  printf '%s%s\n' "${3:+(line $3) }" "${1:-Unknown error. abort...}"
  [[ $- == *i* ]] && return ${2:--1} || exit ${2:--1}
}

# Exports
export -f addpath
export -f die

#alias
alias end='return 0 2>/dev/null || exit 0'
