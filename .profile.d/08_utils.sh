#!/bin/bash
# Bash utils
# see http://tldp.org/LDP/abs/html/

# Alias
alias mountiso='mount -o loop -t iso9660'

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
