#!/bin/sh
MAC="${1?Error: please specify a MAC address}"
IP="${2:-255.255.255.255}"
PORT="${3:-9}"
ITF="${4:-eth0}"
METHOD="$5"
SSHCRED="$6"

# Convert MAC address '-' into ':'
MAC="$(echo "$MAC" | tr '-' ':')"

# Returns true when a given method exists and is selected
_exists() {
  [ -z "$2" ] || [ "$2" = "$1" ] && command -v "$1" >/dev/null 2>&1
}

# Define usable wol URLs
_urls() {
  echo "https://www.depicus.com/wake-on-lan/woli?m=${MAC}&i=${IP}&s=255.255.255.255&p=${PORT}"
  echo "http://www.wakeonlan.me/?mobile=0&ip=${IP}:${PORT}&mac=${MAC}&pass=&schedule=&timezone=0"
}

# Log and run
_run() {
  echo >&2 "$@"; "$@"
}

# Execute the WOL command
if _exists wakeonlan "$METHOD"; then
  _run wakeonlan -i "${IP}" -p "${PORT}" "${MAC}";
elif _exists wol "$METHOD"; then
  _run wol -i "${IP}" -p "${PORT}" "${MAC}"
elif _exists etherwake "$METHOD"; then
  _run etherwake -i "${ITF}" -b "${MAC}"
elif _exists ether-wake "$METHOD"; then
  _run ether-wake -i "${ITF}" -b "${MAC}"
elif _exists curl "$METHOD"; then
  for URL in $(_urls); do
    _run curl -qs "${URL}" >/dev/null && break
  done
elif _exists wget "$METHOD"; then
  for URL in $(_urls); do
    _run wget "${URL}" -q -O /dev/null && break
  done
elif _exists ssh "$METHOD"; then
  true ${SSHCRED:?No ssh credentials specified...}
  # Unset parameters 5-6 (especially METHOD to avoid recursion)
  set -- "$1" "$2" "$3" "$4"
  # Execute local script in remote
  ssh "$SSHCRED" <<EOF
set -- "$1" "$2" "$3" "$4"; $(cat "${RC_DIR:-$HOME}/pbin/wol.sh")
EOF
  # Execute remote script
  #ssh -t "$SSHCRED" -- '${RC_DIR:-$HOME}/pbin/wol.sh' "$@"
else
  echo >&2 "No appropriate WOL method available..."
  false
fi
