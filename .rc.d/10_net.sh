#!/bin/sh

# quvi alias
alias flashdl='quvi'

#wget mirror website
wget_mirror() {
  local SITE=${1:?Please specify the URL}
  local DOMAIN=$(echo "$SITE" | sed -E 's;^https?://([^/]*)/.*$;\1;')
  shift $(min 1 $#)
  wget "$@" --recursive -l${LEVEL:-9999} --no-parent --no-directories --no-clobber --domains ${DOMAIN:?Found no domain} --convert-links --html-extension --page-requisites -e robots=off -U mozilla --limit-rate=${LIMITRATE:-200k} --random-wait "$SITE"
}

# Execute on remote host
alias exec-rem='exec-remote'
exec_remote() {
  local HOST="${1:?No host specified}"
  shift $(min 1 $#)
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

# Send email using mutt or mail
send_mail() {
  local DEST="${1:?No dest email address specified}"
  local SUBJECT="${2:?No subject specified}"
  local CONTENT="${3:?No content specified}"
  local ATTACH="$4"
  local CC="$5"
  local BCC="$6"
  local FROM="$7"
  local SMTP="$8"
  if command -v mutt >/dev/null; then
    echo "$CONTENT" | mutt ${ATTACH:+-a "$ATTACH"} ${SUBJECT:+-s "$SUBJECT"} -- ${DEST} && echo "Email sent"
  elif command -v mail >/dev/null; then
    echo "$CONTENT" | mail ${SUBJECT:+-s "$SUBJECT"} ${DEST} && echo "Email sent"
  elif command -v sendmail >/dev/null; then
    echo "$CONTENT" | sendmail ${DEST} && echo "Email sent"
  elif command -v sendemail >/dev/null; then
    sendemail -q -u "$CONTENT" -f "${FROM:-$USER}" -t "$DEST" ${SMTP:+-s $SMTP} && echo "Email sent"
  else
    echo "No mail program found"
    return 1
  fi
  return 0
}
