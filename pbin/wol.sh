#!/bin/sh
set -e
MAC="${1?Error: please specify a MAC address}"
IP="${2:-255.255.255.255}"
PORT="${3:-9}"
ITF="${4:-eth0}"
METHOD="$5"

# Convert MAC address '-' into ':'
MAC="$(echo $MAC | tr '-' ':')"

# Define usable wol URLs
wol_urls() {
  echo "https://www.depicus.com/wake-on-lan/woli?m=${MAC}&i=${IP}&s=255.255.255.255&p=${PORT}"
  echo "http://www.wakeonlan.me/?mobile=0&ip=${IP}:${PORT}&mac=${MAC}&pass=&schedule=&timezone=0"
}

# Log and run
_run() {
  echo >&2 "$@"; "$@"
}

# Execute the WOL command
if [ -z "$METHOD" ] || [ "$METHOD" = "wakeonlan" ] && command -v wakeonlan >/dev/null 2>&1; then
  _run wakeonlan -i ${IP} -p ${PORT} ${MAC};
elif [ -z "$METHOD" ] || [ "$METHOD" = "wol" ] && command -v wol >/dev/null 2>&1; then
  _run wol -i ${IP} -p ${PORT} ${MAC}
elif [ -z "$METHOD" ] || [ "$METHOD" = "etherwake" ] && command -v etherwake >/dev/null 2>&1; then
  _run etherwake -i ${ITF} -b ${MAC}
elif [ -z "$METHOD" ] || [ "$METHOD" = "curl" ] && command -v curl >/dev/null 2>&1; then
  for URL in $(wol_urls); do
    _run curl -qs "${URL}" >/dev/null && break
  done
elif [ -z "$METHOD" ] || [ "$METHOD" = "wget" ] && command -v wget >/dev/null 2>&1; then
  for URL in $(wol_urls); do
    _run wget "${URL}" -q -O /dev/null && break
  done
else
  echo >&2 "No appropriate WOL method available..."
fi
