#!/bin/bash
trap_stack_name() {
  local sig=${1//[^a-zA-Z0-9]/_}
  echo "__trap_stack_$sig"
}

trap_extract() {
  echo ${@:3:$(($#-3))}
}

trap_get() {
  eval echo $(trap_extract `trap -p $1`)
}

trap_push() {
  local new_trap="$1"
  shift $(min 1 $#)
  for sig in "$@"; do
    stack_name=`trap_stack_name "$sig"`
    old_trap=$(trap_get $sig)
    eval "${stack_name}"'[${#'"${stack_name}"'[@]}]=$old_trap'
    trap "${new_trap}" "$sig"
  done
}

trap_pop() {
  for sig in "$@"; do
    stack_name=`trap_stack_name "$sig"`
    eval 'count=${#'"${stack_name}"'[@]}'
    [[ $count -lt 1 ]] && return 127
    ref="${stack_name}"'[${#'"${stack_name}"'[@]}-1]'
    cmd='new_trap=${'"$ref}"; local new_trap; eval $cmd
    trap "${new_trap}" "$sig"
    eval "unset $ref"
  done
}

trap_prepend() {
  local new_trap="$1"
  shift $(min 1 $#)
  for sig in "$@"; do
    if [[ -z $(trap_get $sig) ]]; then
      trap_push "$new_trap" "$sig"
    else
      trap_push "$new_trap ; $(trap_get $sig)" "$sig"
    fi
  done
}

trap_append() {
  local new_trap="$1"
  shift $(min 1 $#)
  for sig in "$@"; do
    if [[ -z $(trap_get $sig) ]]; then
      trap_push "$new_trap" "$sig"
    else
      trap_push "$(trap_get $sig) ; $new_trap" "$sig"
    fi
  done
}

# Set error handler
trap_map() {
  trap 'die "Error handler:" 1 ${LINENO}' ${@:-1 15} ERR
}

######################################
# Call stack
print_callstack() {
  # skipping i=0 as this is print_call_trace itself
  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    echo -n  ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}:${FUNCNAME[$i]}"(): "
    sed -n "${BASH_LINENO[$i-1]}p" $0
  done
}

# Call stack
print_callstack2() {
  local frame=0
  while caller $frame; do
    ((frame++));
  done
}

################################
# Warn function
warn() {
  echo "${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${FUNCNAME[1]}: ${1:-error}." >&2
}

# Die function
die() {
  warn "${@:2}"
  [[ $- = *i* ]] && {
    echo "Die cannot exit the main shell. Press ctrl-c to stop."
    read
  } || exit ${1:-1};
}
