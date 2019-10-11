#!/bin/sh

############################
# Network monitors
#alias ns='sudo netstat'
#alias nh='sudo nethogs'
#alias nb='sudo bmon'
#alias ns='sudo slurm -s'
#alias nt='sudo tcptrack'
#alias nn='sudo bwm-ng'
#alias nc='sudo cbm'
#alias no='sudo speedometer'
#alias it='iftop'

############################
# Speed limiters
bwctrl0='sudo ethtool'      # sudo ethtool -s eth0 speed 100 #kpbs
bwctrl1='sudo wondershaper' # sudo wondershaper eth0 256 128 #kpbs
bwctrl2='trickle'           # trickle -d 20 -u 20
bwctrl3='pv -L'             # eval ... | pv -L 256kb

############################
# Enable/disable ipv4/v6 until next reboot
alias ipv4_disable='for V in $(sysctl -a -N -r "net.ipv4.conf.*.disable_ipv4"); do sudo sysctl -w $V=1; done'
alias ipv4_enable='for V in $(sysctl -a -N -r "net.ipv4.conf.*.disable_ipv4"); do sudo sysctl -w $V=0; done'
alias ipv6_disable='for V in $(sysctl -a -N -r "net.ipv6.conf.*.disable_ipv6"); do sudo sysctl -w $V=1; done'
alias ipv6_enable='for V in $(sysctl -a -N -r "net.ipv6.conf.*.disable_ipv6"); do sudo sysctl -w $V=0; done'
# Persistent enable/disable ipv4/v6 in sysctl.conf
alias ipv4_disable_persistent='sudo sed -i -e "s/disable_ipv4\s*=.*/disable_ipv4 = 1/" /etc/sysctl.conf'
alias ipv4_enable_persistent='sudo sed -i -e "s/disable_ipv4\s*=.*/disable_ipv4 = 0/" /etc/sysctl.conf'
alias ipv6_disable_persistent='sudo sed -i -e "s/disable_ipv6\s*=.*/disable_ipv6 = 1/" /etc/sysctl.conf'
alias ipv6_enable_persistent='sudo sed -i -e "s/disable_ipv6\s*=.*/disable_ipv6 = 0/" /etc/sysctl.conf'

############################
# iptables list all
iptables_flush() {
  for TABLE in filter nat mangle raw security; do
    echo "** Table $TABLE **"
    sudo iptables -vL -t $TABLE
  done
}

# iptables flush all (must be done by a script at once)
iptables_flush() {
  # Set table filter policies to ACCEPT
  sudo iptables -t filter -P INPUT ACCEPT
  sudo iptables -t filter -P FORWARD ACCEPT
  sudo iptables -t filter -P OUTPUT ACCEPT
  # Remove all existing rules
  for TABLE in filter nat mangle raw security; do
    sudo iptables -t $TABLE -F	# All rules
    sudo iptables -t $TABLE -X	# Delete all user defined-chains (ex: ssh established session)
  done
}

############################
# DHCP client
alias dhcp_renew='sudo dhclient -r; sudo dhclient -1'

############################
# Wget mirror website
alias wget_mirror='wget --mirror --convert-links --adjust-extension --page-requisites --no-parent'
alias wget_flat='wget_mirror -nd'
alias wget_flatflat='wget_mirror -nd -nH'

# Wget download specific extension
wget_ext() {
  local URL="${1:?No url specified...}"
  local EXT="${2:?No extension specified...}"
  shift 2
  wget -r -l1 -H -t1 -nd -N -np --follow-ftp -erobots=off -A$EXT "$URL" "$@"
}

# Wget list urls
wget_ls() {
  wget --spider --force-html --no-directories --no-parent -r -l2 "${@:?No url specified...}" 2>&1 | 
    awk '/^--/{print $3}'
}

# HTML to pdf
alias html_topdf='wkhtmltopdf --margin-bottom 20mm --margin-top 20mm --minimum-font-size 16'
wget_pdf() {
  local NAME
  wget_ls "$@" | while IFS= read -r URL; do
    NAME="${URL%/index.html}"
    NAME="${NAME%/}"
    NAME="${NAME##*/}"
    echo "Processing $URL"
    wkhtmltopdf --margin-bottom 20mm --margin-top 20mm --minimum-font-size 16 "$URL" "${NAME:-index}.pdf"
  done
}

############################
# Execute on remote host
alias remote_exec='exec-remote'
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

############################
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

############################
# Redirect port using socat
socat_bounce() {
  #socat tcp-listen:port,bind=addr,su=nobody,fork,reuseaddr tcp:addr:port
  socat ${5:-tcp}-listen:${1:+$1,}${2:+bind=$2},su=nobody,fork,reuseaddr ${3:+${5:-tcp}:$3${4:+:$4}}
}

# Get public external IP
get_extip() {
  local DNSLOOKUP="ifconfig.me/ip"
  if command -v curl >/dev/null 2>&1; then
    curl -s "$DNSLOOKUP"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$DNSLOOKUP"
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

# Check opened TCP outgoing ports
opened_port_out() {
  for PORT; do
    if command -v nc >/dev/null 2>&1; then
      nc -v portquiz.net "$PORT"
    elif command -v telnet >/dev/null 2>&1; then
      telnet portquiz.net "$PORT"
    elif command -v curl >/dev/null 2>&1; then
      curl "portquiz.net:$PORT"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- "portquiz.net:$PORT"
    elif command -v mimeopen >/dev/null 2>&1; then
      mimeopen "http://portquiz.net:$PORT"
    else
      echo "No suitable command found."
      echo "Open your borwser at: http://portquiz.net:$PORT"
    fi
  done
}

# Check opened TCP input ports
opened_port_in() {
  local HOST="${1:-$(get_extip)}"
  local PORT1="${2:-80}"
  local PORT2="${3:-$PORT1}"
  
  if command -v curl >/dev/null 2>&1; then
    curl -s --request POST 'http://www.ipfingerprints.com/scripts/getPortsInfo.php' \
      --data "remoteHost=$HOST" --data "start_port=$PORT1" --data "end_port=$PORT2" \
      -d normalScan=Yes -d scan_type=connect -d ping_type=none \
    | grep -o open
  else
    echo "No suitable command found."
    echo "Open your borwser at: http://www.ipfingerprints.com/portscan.php"
  fi
}


##############################
# SSH command shortcuts
ssh_ping()        { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh $SSHOPTS -- echo pong; }
ssh_sudo()        { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo "$@"; }
ssh_aria2()       { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output folder specified...}"; shift 2; ssh -t $SSHOPTS -- sh -c "cd \"$DIR\"; aria2c \"$@\""; }
ssh_youtubedl()   { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output folder specified...}"; shift 2; ssh -t $SSHOPTS -- sh -c "cd \"$DIR\"; youtubedl \"$@\""; }

##############################
# Home SSH aliases examples (to be defined in .rc.local)
#alias sshh='command ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias scph='command scp -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias rsynch='command rsync -e "ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config"'

# SSH command shortcuts (rely on sshh, but cannot just alias ssh=sshh, has to create subfunction)
sshh_ping()        { ssh(){ sshh "$@"; }; ssh_ping "$@"; }
sshh_sudo()        { ssh(){ sshh "$@"; }; ssh_sudo "$@"; }
sshh_aria2()       { ssh(){ sshh "$@"; }; ssh_aria2 "$@"; }
sshh_youtubedl()   { ssh(){ sshh "$@"; }; ssh_youtubedl "$@"; }
sshh_tunnel_open() { ssh(){ sshh "$@"; }; ssh_tunnel_open "$@"; }
sshh_proxify()     { ssh(){ sshh "$@"; }; ssh_proxify "$@"; }
sshh_torify()      { ssh(){ sshh "$@"; }; ssh_torify "$@"; }

# ! UNDER TEST !
sshh_vpn_tcp()     { ssh(){ sshh "$@"; }; ssh_vpn_tcp "$@"; }
sshh_vpn_udp()     { ssh(){ sshh "$@"; }; ssh_vpn_udp "$@"; }

##############################
# SSH tunnel shortcuts
# http://www.guiguishow.info/2010/12/28/ssh-du-port-forwarding-au-vpn-bon-marche/#toc-846-la-redirection-dynamique
alias ssh_tunnel='ssh -fnxNT'
ssh_tunnel_open() {
  local SERVER="${1:?No server specified...}"
  shift
  local TUNNEL=""
  for PORT; do
    PORT="$(echo "$PORT" | tr -d '-')"
    TYPE="$(echo "$PORT" | cut -c 1)"
    [ "$TYPE" != "L" -a "$TYPE" != "R" -a "$TYPE" != "D" ] && TYPE="L"
    set -- $(echo "${PORT#$TYPE}" | tr ':' ' ')
    if [ "$TYPE" = "D" ]; then
      TUNNEL="${TUNNEL:+$TUNNEL }-$TYPE $1"
    else
      TUNNEL="${TUNNEL:+$TUNNEL }-$TYPE $1:${2:-127.0.0.1}:${3:-$1}"
    fi
  done
  ssh -fnxNT "$SERVER" $TUNNEL
}
ssh_tunnel_close() {
  for PORT; do
    local LPORT="${PORT%%:*}"
    pgrep -f "ssh.* -(L|R) $LPORT:" | xargs -r kill
    pgrep -f "ssh.* -D $LPORT" | xargs -r kill
  done
}
ssh_tunnel_ls() {
  ps -ef | grep -E "ssh.* -(L|R|D) [0-9]*" | grep -v grep
}

##############################
# TCP VPN via SSH
ssh_vpn_tcp() {
  echo "!!! UNDER TEST !!!"
  local RELAY_ADDR="${1:?No relay address specified...}"
  local RELAY_PORT="${2:?No relay port specified...}"
  local VPN_ADDR="${3:?No VPN address specified...}"
  local VPN_PORT="${4:?No VPN port specified...}"
  local VPN_CONF="${5:?No VPN config file specified...}"
  # Main tunnel
  ssh -fnxNT -L "$RELAY_PORT:$VPN_ADDR:$VPN_PORT" "$RELAY_ADDR"
  # Openvpn blocking call
  ( cd "$(dirname "$VPN_CONF")"
    sudo openvpn --config "$VPN_CONF"
  )
  # Close tunnel
  ssh_tunnel_close "$RELAY_PORT"
}

# UDP VPN via SSH
ssh_vpn_udp() {
  echo "!!! UNDER TEST !!!"
  local RELAY_ADDR="${1:?No relay address specified...}"
  local RELAY_PORT="${2:?No relay port specified...}"
  local VPN_ADDR="${3:?No VPN address specified...}"
  local VPN_PORT="${4:?No VPN port specified...}"
  local VPN_CONF="${5:?No VPN config file specified...}"
  # Main tunnel
  ssh_tunnel_open "$RELAY_ADDR:127.0.0.1:$RELAY_PORT"
  # Setup the relays
  socat -T15 udp-recv:$VPN_PORT tcp:localhost:$RELAY_PORT >/dev/null &
  socat -T15 tcp-listen:localhost:$RELAY_PORT,fork,reuseaddr udp:localhost:$VPN_PORT >/dev/null &
  if [ "$RELAY_ADDR" != "$VPN_ADDR" ]; then
    ssh "$RELAY_ADDR" -- "nohup socat udp-recv:$VPN_PORT tcp:localhost:$RELAY_PORT > /dev/null &"
    ssh "$RELAY_ADDR" -- "nohup socat tcp-listen:$RELAY_PORT,fork,reuseaddr udp:$VPN_ADDR:$VPN_PORT > /dev/null &"
  fi
  # Openvpn blocking call
  ( command cd "$(dirname "$VPN_CONF")"
    sudo openvpn --config "$VPN_CONF"
  )
  # Close the relays
  killall socat
  if [ "$RELAY_ADDR" != "$VPN_ADDR" ]; then
    ssh "$RELAY_ADDR" -- killall socat
  fi
  # Close tunnel
  ssh_tunnel_close "$RELAY_PORT"
  stty sane
}

##############################
# Proxify an app using dynamic SSH tunnels
ssh_proxify() {
  local SERVER="${1:?No server specified...}"
  local LPORT="${2:?No local port specified...}"
  local CONFIG="$HOME/.proxychains/proxychains.conf"
  shift 2
  mkdir -p "$(dirname "$CONFIG")"
  cat > "$CONFIG" <<EOF
strict_chain
quiet_mode
proxy_dns
[ProxyList]
socks5 127.0.0.1 $LPORT
EOF
  ssh_tunnel_open "$SERVER" "D$LPORT" & true
  proxychains "$@"
  ssh_tunnel_close "$LPORT"
}

# Proxify an app using tor
ssh_torify() {
  local SERVER="${1:?No server specified...}"
  local LPORT="${2:?No local port specified...}"
  local DADDR="192.168.8.122"
  local DPORT="5709"
  local CONFIG="$HOME/.proxychains/proxychains.conf"
  shift 2
  mkdir -p "$(dirname "$CONFIG")"
  cat > "$CONFIG" <<EOF
strict_chain
quiet_mode
proxy_dns
[ProxyList]
socks5 127.0.0.1 $LPORT
EOF
  ssh_tunnel_open "$SERVER" "L$LPORT:$DADDR:$DPORT" & true
  proxychains "$@"
  ssh_tunnel_close "$LPORT"
}

##############################
# Add ssh dedicated command id in ~/.ssh/authorized_keys
# Use ssh-copy-id for std login shells
ssh_copy_id() {
  ssh ${1:?No host specified} -p ${2:?No port specified...} -- sh -c "cat 'command=\"${3:?No command specified...},no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${SSH_ORIGINAL_COMMAND#* }\" ${4:?No ssh key specified...}' >> '$HOME/.ssh/authorized_keys'"
}

# Get server remove pubkey
# https://unix.stackexchange.com/questions/126908/get-ssh-server-key-fingerprint
ssh_get_server_pubkey() {
  local FILE="$(mktemp)"
  ssh-keyscan host > "$FILE" 2>/dev/null
  ssh-keygen -l -f "$FILE"
}

############################
# quvi download
quvi_get() {
  quvi "$@" --exec 'wget %u -O %t.%e'
}
