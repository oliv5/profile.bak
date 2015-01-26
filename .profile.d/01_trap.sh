#!/bin/bash
trap-stack-name() {
  local sig=${1//[^a-zA-Z0-9]/_}
  echo "__trap_stack_$sig"
}

trap-extract() {
  echo ${@:3:$(($#-3))}
}

trap-get() {
  eval echo $(trap-extract `trap -p $1`)
}

trap-push() {
  local new_trap=$1
  shift
  local sigs=$*
  for sig in $sigs; do
    local stack_name=`trap-stack-name "$sig"`
    local old_trap=$(trap-get $sig)
    eval "${stack_name}"'[${#'"${stack_name}"'[@]}]=$old_trap'
    trap "${new_trap}" "$sig"
  done
}

trap-pop() {
  local sigs=$*
  for sig in $sigs; do
    local stack_name=`trap-stack-name "$sig"`
    local count; eval 'count=${#'"${stack_name}"'[@]}'
    [[ $count -lt 1 ]] && return 127
    local new_trap
    local ref="${stack_name}"'[${#'"${stack_name}"'[@]}-1]'
    local cmd='new_trap=${'"$ref}"; eval $cmd
    trap "${new_trap}" "$sig"
    eval "unset $ref"
  done
}

trap-prepend() {
  local new_trap=$1
  shift
  local sigs=$*
  for sig in $sigs; do
    if [[ -z $(trap-get $sig) ]]; then
      trap-push "$new_trap" "$sig"
    else
      trap-push "$new_trap ; $(trap-get $sig)" "$sig"
    fi
  done
}

trap-append() {
  local new_trap=$1
  shift
  local sigs=$*
  for sig in $sigs; do
    if [[ -z $(trap-get $sig) ]]; then
      trap-push "$new_trap" "$sig"
    else
      trap-push "$(trap-get $sig) ; $new_trap" "$sig"
    fi
  done
}

# Set error handler
trap-map() {
  trap 'die "Error handler:" 1 ${LINENO}' ${@:-1 15} ERR
}

# Call stack
print-callstack() {
  # skipping i=0 as this is print_call_trace itself
  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    echo -n  ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}:${FUNCNAME[$i]}"(): "
    sed -n "${BASH_LINENO[$i-1]}p" $0
  done
}

