#!/bin/sh
set -e
DBG=

# Extract the command/hostname
NET="${1?Error: please specify a target network: [WAN/LAN]}"
NET="$(echo $NET | awk '{print toupper($0)}')"
MAC="${2?Error: please specify a MAC address}"
ADDR="${3?Error: please specify an IP address or DNS name}"
PORT="${4:-9}"
IF="${5:-eth0}"

echo "Usage:  $(basename $0) <wan/lan> <MAC> <IP/DNS> <port[9]> <itf[eth0]>"
echo "Config: network:$NET  MAC:$MAC  ADDR:$ADDR  PORT:$PORT  IF:$IF"
# Execute the WOL command
case ${NET} in
  LAN)
    if [ `command -v wakeonlan` ]; then
      $DBG wakeonlan -i ${ADDR%.*}.255 -p ${PORT} ${MAC}
    elif [ `command -v wol` ]; then
      $DBG wol -i ${ADDR%.*}.255 -p ${PORT} ${MAC}
    elif [ `command -v ether-wake` ]; then
      $DBG ether-wake -i ${IF} -b ${MAC}
    else
      echo "No appropriate LAN WOL software available..."
    fi
    ;;
  WAN)
    if [ `command -v wakeonlan` ]; then
      $DBG wakeonlan -i ${ADDR} -p ${PORT} ${MAC}
    elif [ `command -v wol` ]; then
      $DBG wol -i ${ADDR} -p ${PORT} ${MAC}
    else
      echo "No appropriate WAN WOL software available..."
    fi
    ;;
  *)
    echo "Unknown network [WAN/LAN]..."
    ;;
esac
