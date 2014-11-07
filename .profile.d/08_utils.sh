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
  OPTS="${@:2}"
  wget $OPTS --recursive -l${LEVEL:-9999} --no-parent --no-directories --no-clobber --domains ${DOMAIN:?Found no domain} --convert-links --html-extension --page-requisites -e robots=off -U mozilla --limit-rate=${LIMITRATE:-200k} --random-wait "$SITE"
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

# Get public external IP
function get-extip() {
  DNSLOOKUP="ifconfig.me/ip"
  if command -v curl >/dev/null; then
    curl $DNSLOOKUP
  elif command -v wget >/dev/null; then
    wget -qO- $DNSLOOKUP
  else
    HOST=${DNSLOOKUP%%/*}
    URL=${DNSLOOKUP#*/}
    exec 3</dev/tcp/$HOST/80
    sed 's/ *//' <<< "
      GET /$URL HTTP/1.1
      connection: close
      host: $HOST
      " >&3
    grep -oE '([0-9]+\.){3}[0-9]+' <&3
  fi
}

# Strip ANSI codes
alias rm-ansi='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'

# Send email using mutt or mail
function send-mail() {
  DEST="${1:?No email address specified}"
  SUBJECT="${2:?No subject specified}"
  CONTENT="${3:?No content specified}"
  ATTACH="$4"
  CC="$5"
  BCC="$6"
  if command -v mutt >/dev/null; then
    echo -e "$CONTENT" | mutt ${ATTACH:+-a "$ATTACH"} ${SUBJECT:+-s "$SUBJECT"} -- ${DEST} && echo "Email sent"
  elif command -v mail >/dev/null; then
    echo -e "$CONTENT" | mail ${SUBJECT:+-s "$SUBJECT"} ${DEST} && echo "Email sent"
  else
    echo "No mail program found"
    return 1
  fi
  return 0
}
