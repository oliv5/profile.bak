#!/bin/sh
SSH_OPTS="-C -oCompressionLevel=9 -o ConnectTimeout=10"

# Convert input arguments into a command line for the selected host shell
function _ssh-concat()
{
  CMD=""
  while [ $# != 0 ]; do
    CMD="${CMD}${1:+${CMD:+ $SSHPACK_SEPARATOR }$1}"
    shift
  done
  echo "${CMD}"
}

function ssh-agent() {
  ssh-config
  killall -e ssh-agent
  eval $($(which ssh-agent) -t 7200 "$@")
  ssh-add $SSHPACK_PKEY
}

function ssh-boot() {
  ssh-config
  #URI="http://www.wakeonlan.me/?mobile=0&ip=${SSHPACK_IP}:${SSHPACK_WOLPORT}&mac=${SSHPACK_MAC}&pass=&schedule=&timezone=0"
  URI="http://www.depicus.com/wake-on-lan/woli.aspx?m=${SSHPACK_MAC//-/}&i=${SSHPACK_IP}&s=255.255.255.255&p=${SSHPACK_HOST}"
  wget ${URI} -o /dev/null -O /dev/null 2> /dev/null
}

function ssh-wol() {
  ssh-config
  if [ -n "$1" ]; then
    ssh-sudo wol.sh WAN $SSHPACK_MAC $SSHPACK_IP $SSHPACK_WOLPORT $SSHPACK_WOLITF
  else
    wol.sh WAN $SSHPACK_MAC $SSHPACK_IP $SSHPACK_WOLPORT $SSHPACK_WOLITF
  fi
}

function ssh-scp() {
  ssh-config
  [ -n "$SSHPACK_DBG" ] && set -x
  scp $SSH_OPTS -P ${SSHPACK_SSHPORT} -i "${SSHPACK_PKEY}" "$@"
  [ -n "$SSHPACK_DBG" ] && set +x
}

function ssh-shell() {
  ssh-config
  [ -n "$SSHPACK_DBG" ] && set -x
  ssh $SSH_OPTS -p ${SSHPACK_SSHPORT} -i "${SSHPACK_PKEY}" "${1-${SSHPACK_USER}}@${SSHPACK_HOST}" ${@:2}
  [ -n "$SSHPACK_DBG" ] && set +x
}

function ssh-sftp() {
  ssh-config
  [ -n "$SSHPACK_DBG" ] && set -x
  sftp $SSH_OPTS -oPort=${SSHPACK_SSHPORT} -oIdentityFile="${SSHPACK_PKEY}" -b /dev/stdin "${1-${SSHPACK_USER}}@${SSHPACK_HOST}" ${@:2}
  [ -n "$SSHPACK_DBG" ] && set +x
}

function ssh-plink() {
  ssh-config
  [ -n "$SSHPACK_DBG" ] && set -x
  ssh $SSH_OPTS -p ${SSHPACK_SSHPORT} -i "${SSHPACK_PKEY}" "${1-${SSHPACK_USER}}@${SSHPACK_HOST}" ${@:2}
  [ -n "$SSHPACK_DBG" ] && set +x
}

function ssh-exec() {
  ssh-config
  ssh-plink ${SSHPACK_USER} "$@"
}

function ssh-sudo() {
  ssh-config
  ssh-plink ${SSHPACK_ROOT} "$@"
}

function ssh-ping() {
  ssh-config
  echo ping ...
  ssh-exec "echo pong!"
}

function ssh-shutdown() {
  ssh-config
  echo Remote shutdown
  echo Press a key... ; read
  ssh-sudo ${SSHPACK_SHUTDOWN}
}

function ssh-stopwd() {
  ssh-config
  echo Stop watchdog
  ssh-sudo ${SSHPACK_STOPWD}
}

function _ssh-tunnel() {
  true ${1?Error: please specify a service name...}
  if [[ $1 =~ ^[0-9]+$ ]] ; then
    PORTS="$@"
  else
    SVC=$(echo "$1" | tr "[:lower:]" "[:upper:]")
    VAR="SSHPACK_${SVC}_PORT"
    PORTS="${!VAR}"
  fi
  TUNNEL=""
  for PORT in $PORTS; do
    TUNNEL="${TUNNEL} -L ${PORT}:127.0.0.1:${PORT}"
  done
  echo "${TUNNEL# }"
}

function ssh-tunnel() {
  #ssh-sudo $(_ssh-tunnel "$@") ${SSHPACK_SHELL} \"$(_ssh-concat ${SSHPACK_PAUSE} ${SSHPACK_PAUSE})\"
  ssh-sudo -fnxNT $(_ssh-tunnel "$@")
}

function ssh-kill_tunnel() {
  ps -ef | grep -v grep | grep "ssh.*$SSHPACK_HOST.*$(_ssh-tunnel $@)" | awk '{print $2;}' | xargs kill 2>/dev/null
}

function ssh-session() {
  ssh-config

  # Variables
  BOOT="1"
  CLOSEDOWN="0"
  SHUTDOWN="0"

  # SSH agent
  ssh-agent

  # Boot
  if [[ "${BOOT}" = "1" ]] ; then
    echo "Boot host..."
    ssh-boot
  fi

  # Wait idle
  echo "Ping..."
  ERROR=$(ssh-ping)
  until [[ "$ERROR" != "0" ]] ; do
    sleep 10s
    ERROR=$(ssh-ping)
  done
  ssh-stopwd
  echo "Host is up and ready..."

  # Setup services
  if [[ -n "${SSHPACK_SESSION_START}" ]] ; then
    echo "Setup SSH services..."
    ssh-sudo "${SSHPACK_SESSION_START}"
  fi
  
  # Setup VPN
  ssh-tunnel VPND
  sudo openvpn --config ${SSHPACK_PATH}/etc/openvpn/linux/${SSHPACK_VPND_CFG}
  ssh-kill_tunnel VPND

  # Closedown
  if [[ -n "${SSHPACK_SESSION_STOP}" ]] ; then
    echo "Stop SSH services..."
    ssh-sudo "${SSHPACK_SESSION_STOP}"
  fi

  # Shutdown
  if [[ "${SHUTDOWN}" = "1" ]] ; then
    echo "Shutdown ..."
    ssh-shutdown
  fi
}
