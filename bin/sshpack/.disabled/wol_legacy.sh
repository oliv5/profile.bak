#!/bin/sh
set -e
DBG=
INTERFACE_LAN=lan0

# Define a new host
nas=0
eval hostname_${nas}='nas'
eval hostmac_${nas}='00:15:E9:F0:7B:EE'
eval hostdns_${nas}='oliv5kta.dyndns.org'
eval hostiplocal_${nas}='127.0.0.1'
eval hostiplan_${nas}='192.168.8.127'
eval hostipvpn_${nas}='192.168.8.127'
eval hostipwan_${nas}=''
eval hostwolport_${nas}=7
eval hostcmdurl_${nas}='http://${IP}:5902/pub/system/server/'
# use eval for hostcmdurl

# Define a new host
u36sd=1
eval hostname_${u36sd}='u36sd'
eval hostmac_${u36sd}='14:DA:E9:36:87:B9'
eval hostdns_${u36sd}='oliv5kta.dyndns.org'
eval hostiplocal_${u36sd}='127.0.0.1'
eval hostiplan_${u36sd}='192.168.8.128'
eval hostipvpn_${u36sd}='192.168.8.128'
eval hostipwan_${u36sd}=''
eval hostwolport_${u36sd}=9
eval hostcmdurl_${u36sd}='http://${IP}:5902/pub/system/server/'
# use eval for hostcmdurl

# Define a new host
rpi=2
eval hostname_${rpi}='rpi'
eval hostmac_${rpi}='00:17:3f:12:97:58'
eval hostdns_${rpi}='oliv5kta.dyndns.org'
eval hostiplocal_${rpi}='127.0.0.1'
eval hostiplan_${rpi}='192.168.8.126'
eval hostipvpn_${rpi}='192.168.8.126'
eval hostipwan_${rpi}=''
eval hostwolport_${rpi}=9
eval hostcmdurl_${rpi}='http://${IP}:5902/'
# use eval for hostcmdurl

# Extract the command/hostname
CMD=${1#*-}
HOSTNAME=${1%%-*}
INTERFACE=${2:-$INTERFACE_LAN}
HOSTID=$(eval echo \$${HOSTNAME})
HOSTDNS=$(eval echo \$hostdns_$HOSTID)
HOSTIPLAN=$(eval echo \$hostiplan_$HOSTID)
HOSTIPWAN=$(eval echo \$hostipwan_$HOSTID)
HOSTPORT=$(eval echo \$hostwolport_$HOSTID)
HOSTMAC=$(eval echo \$hostmac_$HOSTID)

if [ -z "${HOSTNAME}" -o -z "${HOSTID}" ]; then
  echo "Usage: $(basename $0) hostname-[wan|lan]"
  echo "Host '${HOSTNAME}' unknown"
  echo "Known hosts: ${hostname_0} ${hostname_1} ${hostname_2}"
  exit 1
fi

# Execute the WOL command
case ${CMD:-LAN} in
  lan)
    echo Using configuration for LAN
    if [ `command -v wakeonlan` ]; then
      $DBG wakeonlan -i ${HOSTIPLAN%.*}.255 -p ${HOSTPORT} ${HOSTMAC}
    elif [ `command -v ether-wake` ]; then
      $DBG ether-wake -i ${INTERFACE} -b ${HOSTMAC}
    elif [ `command -v wol` ]; then
      $DBG wol -i ${HOSTIPLAN%.*}.255 -p ${HOSTPORT} ${HOSTMAC}
    else
      echo No appropriate WOL software available...
    fi
    ;;
  *)
    echo Using configuration for WAN
    if [ `command -v wakeonlan` ]; then
      $DBG wakeonlan -i ${HOSTIPWAN:-${HOSTDNS}} -p ${HOSTPORT} ${HOSTMAC}
    elif [ `command -v wol` ]; then
      $DBG wol -i ${HOSTIPWAN:-${HOSTDNS}} -p ${HOSTPORT} ${HOSTMAC}
    else
      echo No appropriate WOL software available...
    fi
    ;;
esac
