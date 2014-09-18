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

function mkbak() {
  cp "${1:?Please specify input file 1}" "${1}.$(date +%Y%m%d-%H%M%S).bak"
}

# Get password
function get-passwd() {
  trap "stty echo; trap SIGINT" SIGINT; stty -echo
  read -p "${1:-Password: }" PASSWD; echo
  stty echo; trap SIGINT
  echo $PASSWD
}

#wget mirror website
function wget-mirror() {
  SITE=${1:?Please specify the URL}
  DOMAIN=$(sed -E 's;^https?://([^/]*)/.*$;\1;' <<< $SITE)
  LEVEL=9999
  LIMITRATE=200k
  wget --recursive -l$LEVEL --no-parent --no-directories --no-clobber --domains $DOMAIN --convert-links --html-extension --page-requisites -e robots=off -U mozilla --limit-rate=$LIMITRATE --random-wait $SITE
}

# Hex to signed decimal
function hex2int() {
	#MAX=$(( 1 << ${2:-32} ))
	#MEAN=$(($(($MAX >> 1)) - 1))
	let "MAX=1<<${2:-32}"
	let "MEAN=($MAX >> 1) - 1"
    RES=$(printf "%d" "$1")
    (( RES > $MEAN )) && (( RES -= $MAX )) 
    echo $RES
}

# Execute on remote host
alias exec-rem='exec-remote'
function exec-remote() {
  CMD="${2:?No command specified} ${@:3}"
  if [ "${1:?No host specified}" != "$HOSTNAME" ]; then
	\ssh -X $1 "$CMD"
  else
    eval "\\$CMD"
  fi
}
