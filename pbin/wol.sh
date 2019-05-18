#!/bin/sh
MAC="${1?Error: please specify a MAC address}"
ADDR="${2:-255.255.255.255}"
PORT="${3:-9}"
ITF="${4:-eth0}"
NET="${5:-wan}"
# Convert MAC address '-' into ':'
MAC="$(echo $MAC | tr '-' ':')"
# Set broadcast address
if [ "$NET" = "lan" ] || [ "$NET" = "lan" ]; then
  ADDR=${ADDR%.*}.255
fi
# Message
echo "Usage:  wol.sh <MAC> <IP/DNS> <port[9]> <itf[eth0]>"
echo "Config: MAC:$MAC  ADDR:$ADDR  PORT:$PORT  ITF:$ITF"
# Execute the WOL command
if command -v wakeonlan >/dev/null 2>&1; then
  wakeonlan -i ${ADDR} -p ${PORT} ${MAC};
elif command -v wol >/dev/null 2>&1; then
  wol -i ${ADDR} -p ${PORT} ${MAC}
elif command -v ether-wake >/dev/null 2>&1; then
  ether-wake -i ${ITF} -b ${MAC}
elif command -v curl >/dev/null 2>&1; then
  URI="https://www.depicus.com/wake-on-lan/woli?m=${MAC}&i=${ADDR}&s=255.255.255.255&p=${PORT}"
  curl "${URI}"
elif command -v wget >/dev/null 2>&1; then
  #URI="http://www.wakeonlan.me/?mobile=0&ip=${ADDR}:${PORT}&mac=${MAC}&pass=&schedule=&timezone=0"
  URI="https://www.depicus.com/wake-on-lan/woli?m=${MAC}&i=${ADDR}&s=255.255.255.255&p=${PORT}"
  wget "${URI}" -q -O /dev/null
else
  echo "No appropriate WOL method available..."
fi
