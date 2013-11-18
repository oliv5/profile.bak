#!/bin/bash
# Bash utils
# see http://tldp.org/LDP/abs/html/

# Alias
alias mountiso='mount -o loop -t iso9660'

# Call stack
function print_call_trace()
{
    # skipping i=0 as this is print_call_trace itself
    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        echo -n  ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}:${FUNCNAME[$i]}"(): "
        sed -n "${BASH_LINENO[$i-1]}p" $0
    done
}

# To lower
function toLower()
{
  echo "${@}" | tr "[:upper:]" "[:lower:]"
}

# To upper
function toUpper()
{
  echo "${@}" | tr "[:lower:]" "[:upper:]"
}

# Get password
function getpwd() {
  trap "stty echo; trap SIGINT" SIGINT; stty -echo
  read -p "${1:-Password: }" PASSWD; echo
  stty echo; trap SIGINT
  echo $PASSWD
}
