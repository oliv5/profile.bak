#!/bin/sh

################################
# To lower
toLower() {
  echo "${@}" | tr "[:upper:]" "[:lower:]"
}

# To upper
toUpper() {
  echo "${@}" | tr "[:lower:]" "[:upper:]"
}

################################
# Create file backup
mkbak() {
  cp "${1:?Please specify input file 1}" "${1}.$(date +%Y%m%d-%H%M%S).bak"
}

# Ask and expect one of the given answer
askuser() {
  local ANSWER;
  read ${1:+-p "$1"} ANSWER
  shift
  for ACK; do
    [ "$ANSWER" = "$ACK" ] && return 0
  done
  return 1
}

# Get password
get_passwd() {
  local PASSWD
  trap "stty echo; trap SIGINT" SIGINT; stty -echo
  read -p "${1:-Password: }" PASSWD; echo
  stty echo; trap SIGINT
  echo $PASSWD
}

#wget mirror website
wget_mirror() {
  local SITE=${1:?Please specify the URL}
  local DOMAIN=$(echo "$SITE" | sed -E 's;^https?://([^/]*)/.*$;\1;')
  shift; local OPTS="$@"
  wget $OPTS --recursive -l${LEVEL:-9999} --no-parent --no-directories --no-clobber --domains ${DOMAIN:?Found no domain} --convert-links --html-extension --page-requisites -e robots=off -U mozilla --limit-rate=${LIMITRATE:-200k} --random-wait "$SITE"
}

# Hex to signed 32
hex2int32() {
  local MAX=$((1<<${2:-32}))
  local MEAN=$(($(($MAX>>1))-1))
  local RES=$(printf "%d" "$1")
  [ $RES -gt $MEAN ] && RES=$((RES-MAX))
  echo $RES
}

# Hex to signed 64
hex2int64() {
  local MAX=$((1<<${2:-64}))
  local MEAN=$(($(($MAX>>1))-1))
  local RES=$(printf "%d" "$1")
  [ $RES -gt $MEAN ] && RES=$((RES-MAX))
  echo $RES
}

# Hex to unsigned 64
hex2uint32() {
  printf "%d" "$1"
}

# Hex to unsigned 64
uint2hex() {
  printf "0x%x" "$1"
}

# Execute on remote host
alias exec-rem='exec-remote'
exec_remote() {
  local HOST="${1:?No host specified}"
  shift
  local CMD="${@:?No command specified}"
  if [ "$HOST" != "$HOSTNAME" ]; then
    ssh -X $HOST "$CMD"
  else
    eval "\\$CMD"
  fi
}

# Get public external IP
get_extip() {
  local DNSLOOKUP="ifconfig.me/ip"
  if command -v curl >/dev/null; then
    curl $DNSLOOKUP
  elif command -v wget >/dev/null; then
    wget -qO- $DNSLOOKUP
  else
    local HOST="${DNSLOOKUP%%/*}"
    local URL="${DNSLOOKUP#*/}"
    exec 3</dev/tcp/$HOST/80
    #sed 's/ *//' <<< "
    #  GET /$URL HTTP/1.1
    #  connection: close
    #  host: $HOST
    #  " >&3
    echo >&3 << EOL
GET /$URL HTTP/1.1
connection: close
host: $HOST
EOL
    grep -oE '([0-9]+\.){3}[0-9]+' <&3
  fi
}

# Strip ANSI codes
alias rm-ansi='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'

# Send email using mutt or mail
send_mail() {
  local DEST="${1:?No email address specified}"
  local SUBJECT="${2:?No subject specified}"
  local CONTENT="${3:?No content specified}"
  local ATTACH="$4"
  local CC="$5"
  local BCC="$6"
  if command -v mutt >/dev/null; then
    echo "$CONTENT" | mutt ${ATTACH:+-a "$ATTACH"} ${SUBJECT:+-s "$SUBJECT"} -- ${DEST} && echo "Email sent"
  elif command -v mail >/dev/null; then
    echo "$CONTENT" | mail ${SUBJECT:+-s "$SUBJECT"} ${DEST} && echo "Email sent"
  else
    echo "No mail program found"
    return 1
  fi
  return 0
}

# Convert to libreoffice formats
conv_soffice() {
  FORMAT="${1:?No output format specified}"; shift
  FILES="$@"
  unoconv -f "$FORMAT" "$FILES" ||
    soffice --headless --convert-to "$FORMAT" "$FILES"
}
