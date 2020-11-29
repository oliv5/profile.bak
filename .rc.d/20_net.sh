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
# Local IP addr get
ip_addr_get() {
  local FILTER="${1:-inet}"
  if [ $# -gt 1 ]; then
    shift
    for DEV; do
      ip address show dev "$DEV"
    done
  else
    ip address
  fi | awk "/$FILTER/ {print \$2}"
}

ipv4_addr_get() {
  ip_addr_get "inet " "$@"
}

ipv6_addr_get() {
  ip_addr_get "inet6" "$@"
}

############################
# Local IP addr monitor
ip_monit() {
  for DEV; do
    sh -c "ip monitor address dev '$DEV'" &
  done
}
ip_monit_new() {
  for DEV; do
    sh -c "ip monitor address dev '$DEV' | awk '! /Deleted/ && /inet/ {system(\". ip.monit.send.sh '$DEV' \" \$4 )}' " &
  done
}
ip_monit_del() {
  for DEV; do
    sh -c "ip monitor address dev '$DEV' | awk '/Deleted/ && /inet/ {system(\". ip.monit.send.sh '$DEV' \" \$4 )}' " &
  done
}

############################
# IPv6
ipv6_supported() {
  test -f /proc/net/if_inet6 && echo "IPv6 supported" || echo "IPv6 not supported"
}
ipv6_enabled() {
  sysctl -a 2>/dev/null | grep disable_ipv6
}

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

############################
# Ssh running sudo and pipe
# Use full for piping ssh sudo output
# Ex: (ask_passwd; echo) | ssh -tt user@server "sudo -k -S 2>/dev/null dd if=/dev/mmcblk0" | dd of=image.dat status=progress
ssh_sudo_askpass() {
  local SSH_OPTS="${1:?No ssh server/opts specified...}"
  shift
  ask_passwd | ssh -tt "$SSH_OPTS" 'cat - | sudo -S "$@"'
}

##############################
# SSH command shortcuts
ssh_ping()        { local SSH_OPTS="${SSH_OPTS:+$SSH_OPTS }${1:?No server or ssh option specified...}"; shift; ssh $SSH_OPTS -- echo pong; }
ssh_sudo()        { local SSH_OPTS="${SSH_OPTS:+$SSH_OPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSH_OPTS -- sudo "$@"; }
ssh_aria2()       { local SSH_OPTS="${SSH_OPTS:+$SSH_OPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output folder specified...}"; shift 2; ssh -t $SSH_OPTS -- sh -c "cd \"$DIR\"; aria2c \"$@\""; }
ssh_youtubedl()   { local SSH_OPTS="${SSH_OPTS:+$SSH_OPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output folder specified...}"; shift 2; ssh -t $SSH_OPTS -- sh -c "cd \"$DIR\"; youtubedl \"$@\""; }

##############################
# Home SSH aliases examples (to be defined in .rc.local)
#alias sshh='command ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias scph='command scp -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias rsynch='command rsync -e "ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config"'
#sshh_proxify() { ssh(){ sshh "$@"; }; local SRV="$1"; shift; ssh_proxify "$SRV" "16000" "$@"; }
#sshh_torify()  { ssh(){ sshh "$@"; }; local SRV="$1"; shift; ssh_torify "$SRV" "16001" "192.168.8.122" "5709" "$@"; }

# SSH command shortcuts (rely on sshh, but cannot just alias ssh=sshh, has to create subfunction)
sshh()             { command ssh "$@"; } # default transparent ssh command
sshh_ping()        { ssh(){ sshh "$@"; }; ssh_ping "$@"; }
sshh_sudo()        { ssh(){ sshh "$@"; }; ssh_sudo "$@"; }
sshh_aria2()       { ssh(){ sshh "$@"; }; ssh_aria2 "$@"; }
sshh_youtubedl()   { ssh(){ sshh "$@"; }; ssh_youtubedl "$@"; }
sshh_tunnel_open() { ssh(){ sshh "$@"; }; ssh_tunnel_open "$@"; }
sshh_proxify()     { ssh(){ sshh "$@"; }; ssh_proxify "$@"; }
sshh_proxify_ff()  { ssh(){ sshh "$@"; }; ssh_proxify_ff "$@"; }
sshh_torify()      { ssh(){ sshh "$@"; }; ssh_torify "$@"; }
sshh_torify_ff()   { ssh(){ sshh "$@"; }; ssh_torify_ff "$@"; }
sshh_socat_vpn_p2p() { ssh(){ sshh "$@"; }; ssh_socat_vpn_p2p "$@"; }
sshh_socat_vpn()     { ssh(){ sshh "$@"; }; ssh_socat_vpn "$@"; }
sshh_vpn()         { ssh(){ sshh "$@"; }; ssh_vpn "$@"; }
sshh_shuttle()     { ssh(){ sshh "$@"; }; ssh_shuttle "$@"; }

##############################
# SSH tunnel shortcuts
# http://www.guiguishow.info/2010/12/28/ssh-du-port-forwarding-au-vpn-bon-marche/#toc-846-la-redirection-dynamique
alias ssh_tunnel='ssh -fnxNT'
_ssh_tunnel_open() {
  local SSHOPTS="${1:?No ssh options specified...}"
  local SERVER="${2:?No server specified...}"
  shift 2
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
  ssh -${SSHOPTS} -nxNT "$SERVER" $TUNNEL
}
ssh_tunnel_open() {
  _ssh_tunnel_open -f "$@"
}
ssh_tunnel_open4() {
  _ssh_tunnel_open -f4 "$@"
}
ssh_tunnel_close() {
  for PORT; do
    local LPORT="${PORT%%:*}"
    pgrep -f "ssh.* -(L|R) ?${LPORT}:" | xargs -r kill -9
    pgrep -f "ssh.* -D ?$LPORT" | xargs -r kill -9
  done
}
ssh_tunnel_ls() {
  ps -ef | grep -E "ssh.* -(L|R|D) [0-9]*" | grep -v grep
}

##############################
#~ # TCP openvpn via SSH
#~ sshh_openvpn_tcp() { ssh(){ sshh "$@"; }; ssh_openvpn_tcp "$@"; }
#~ ssh_openvpn_tcp() {
  #~ echo "!!! UNDER TEST !!!"
  #~ local RELAY_ADDR="${1:?No relay address specified...}"
  #~ local RELAY_PORT="${2:?No relay port specified...}"
  #~ local VPN_ADDR="${3:?No VPN address specified...}"
  #~ local VPN_PORT="${4:?No VPN port specified...}"
  #~ local VPN_CONF="${5:?No VPN config file specified...}"
  #~ # Main tunnel
  #~ ssh -fnxNT -L "$RELAY_PORT:$VPN_ADDR:$VPN_PORT" "$RELAY_ADDR"
  #~ # Openvpn blocking call
  #~ ( cd "$(dirname "$VPN_CONF")"
    #~ sudo openvpn --config "$VPN_CONF"
  #~ )
  #~ # Close tunnel
  #~ ssh_tunnel_close "$RELAY_PORT"
#~ }

#~ # UDP openvpn via SSH
#~ sshh_openvpn_udp() { ssh(){ sshh "$@"; }; ssh_openvpn_udp "$@"; }
#~ ssh_openvpn_udp() {
  #~ echo "!!! UNDER TEST !!!"
  #~ local RELAY_ADDR="${1:?No relay address specified...}"
  #~ local RELAY_PORT="${2:?No relay port specified...}"
  #~ local VPN_ADDR="${3:?No VPN address specified...}"
  #~ local VPN_PORT="${4:?No VPN port specified...}"
  #~ local VPN_CONF="${5:?No VPN config file specified...}"
  #~ # Main tunnel
  #~ ssh -fnxNT -L "$RELAY_PORT:127.0.0.1:$VPN_PORT" "$RELAY_ADDR"
  #~ # Setup the relays
  #~ if [ "$RELAY_ADDR" != "$VPN_ADDR" ]; then
    #~ ssh "$RELAY_ADDR" -- "nohup socat tcp-listen:$RELAY_PORT,fork,reuseaddr udp-sendto:$VPN_ADDR:$VPN_PORT > /dev/null &"
  #~ fi
  #~ # Openvpn blocking call
  #~ ( command cd "$(dirname "$VPN_CONF")"
    #~ sudo openvpn --config "$VPN_CONF"
  #~ )
  #~ # Close the relays
  #~ killall socat
  #~ if [ "$RELAY_ADDR" != "$VPN_ADDR" ]; then
    #~ ssh "$RELAY_ADDR" -- killall socat
  #~ fi
  #~ # Close tunnel
  #~ ssh_tunnel_close "$RELAY_PORT"
  #~ stty sane
#~ }

##############################
# Point-to-point socat VPN through SSH
ssh_socat_vpn_p2p() {
  local RELAY_ADDR="${1:?No relay address specified...}"
  local RELAY_PORT="${2:-16000}"
  local VPN_ADDR_SRV="${3:-192.168.9.1/24}"
  local VPN_ADDR_CLIENT="${4:-192.168.9.2/24}"
  local BACKGROUND="${5:+-b}"
  # Set server TUN interface up; no fork, one connection only (no need to close it after use)
  ssh_sudo "$RELAY_ADDR" -b socat "tcp-listen:$RELAY_PORT,reuseaddr" "tun:$VPN_ADDR_SRV,up"
  # Set tunnel up; sleep 30s then close when tunnel is no in use (no need to close it after use)
  ssh -fxT -L "$RELAY_PORT:127.0.0.1:$RELAY_PORT" "$RELAY_ADDR" sleep 30
  # Set client TUN interface up. Blocks until user is done with it
  sudo $BACKGROUND socat "tcp:127.0.0.1:$RELAY_PORT" "tun:$VPN_ADDR_CLIENT,up"
}

# Point-to-point socat VPN through SSH with routing
#sudo socat -d -d tcp-listen:16000,reuseaddr,fork tun:192.168.4.1/24,up
#sudo socat tcp:127.0.0.1:16000 tun:192.168.4.2/24,up
#sudo ip route add 192.168.8.0/24 dev tun0 via 192.168.4.1
#sudo echo 1 > /proc/sys/net/ipv4/ip_forward
#sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE # eth0 is the outgoing interface which need masquerade
ssh_socat_vpn() {
  local RELAY_ADDR="${1:?No relay address specified...}"
  local RELAY_PORT="${2:-16000}"
  local VPN_ADDR_SRV="${3:-192.168.9.1/24}"
  local VPN_ADDR_CLIENT="${4:-192.168.9.2/24}"
  local LOCAL_TUN="${5:-tun0}"
  local REMOTE_ITF="${6:-eth0}"
  local LOCAL_ROUTES="$7"
  # Set IP forwarding
  # Set masquerading on eth0 (the remote output interface which needs address rewriting)
  # Set server TUN interface up; no fork, one connection only (no need to close it after use)
  ssh_sudo "$RELAY_ADDR" -b sh -c "\"
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -o $REMOTE_ITF -j MASQUERADE
    socat \"tcp-listen:$RELAY_PORT,reuseaddr\" \"tun:$VPN_ADDR_SRV,up\"
    iptables -t nat -D POSTROUTING -o $REMOTE_ITF -j MASQUERADE
  \"" _
  # Set tunnel up; sleep 30s then close when tunnel is no in use (no need to close it after use)
  ssh -fxT -L "$RELAY_PORT:127.0.0.1:$RELAY_PORT" "$RELAY_ADDR" sleep 30
  # Set client TUN interface up. Blocks until user is done with it
  sudo socat "tcp:127.0.0.1:$RELAY_PORT" "tun:$VPN_ADDR_CLIENT,up" &
  sleep 1
  # Set local routes
  sudo ip route add "VPN_ADDR_SRV" via "${VPN_ADDR_SRV%/*}"
  for ROUTE in $LOCAL_ROUTES; do
    sudo ip route add "$ROUTE" dev "$LOCAL_TUN" via "${VPN_ADDR_SRV%/*}"
  done
  # Wait childs or user input
  echo "ctrl-c to stop vpn"
  wait
}

##############################
# Point-to-point ssh VPN with routing
ssh_vpn() {
  local RELAY_ADDR="${1:?No relay address specified...}"
  local LOCAL_ROUTES="$2"
  local LOCAL_ADDR="${3:-192.168.99.2/24}"
  local LOCAL_TUN="${4:-99}"
  local REMOTE_ADDR="${5:-192.168.99.1/24}"
  local REMOTE_TUN="${6:-99}"
  local REMOTE_OUTPUT_ITF="${7:-eth0}"
  # Local tun setup
  sudo ip tuntap add "tun$LOCAL_TUN" mode tun
  sudo ip addr add "$LOCAL_ADDR" dev "tun$LOCAL_TUN"
  sudo ip link set dev "tun$LOCAL_TUN" up
  # Remote tun setup
  ssh_sudo "$RELAY_ADDR" -b sh -c "\"
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -o $REMOTE_OUTPUT_ITF -j MASQUERADE
    sudo ip tuntap add \"tun$REMOTE_TUN\" mode tun
    sudo ip addr add \"$REMOTE_ADDR\" dev \"tun$REMOTE_TUN\"
    sudo ip link set dev \"tun$REMOTE_TUN\" up
  \"" _
  # Set tun tunnel up
  ssh -f -w "${LOCAL_TUN}:${REMOTE_TUN}" "$RELAY_ADDR" true
  sleep 1
  # Set local routes
  sudo ip route add "$REMOTE_ADDR" via "${REMOTE_ADDR%/*}"
  for ROUTE in $LOCAL_ROUTES; do
    sudo ip route add "$ROUTE" via "${REMOTE_ADDR%/*}"
  done
  # Wait childs or user input
  echo "ctrl-c to stop vpn"
  read _
  # Kill tunnel
  pgrep -f "ssh.* -w ${LOCAL_TUN}:${REMOTE_TUN}" | xargs -r kill
  # Remove remote tun
  ssh_sudo "$RELAY_ADDR" -b sh -c "\"
    iptables -t nat -D POSTROUTING -o $REMOTE_OUTPUT_ITF -j MASQUERADE
    sudo ip link set dev \"tun$REMOTE_TUN\" down
    sudo ip tuntap delete \"tun$REMOTE_TUN\" mode tun
  \"" _
  # Remove local tun
  sudo ip link set dev "tun$REMOTE_TUN" down
  sudo ip tuntap delete "tun$REMOTE_TUN" mode tun
}

##############################
# Set firefox proxy profile
firefox_set_proxy() {
  local PORT="${1:-16000}"
  local PROFILE="${2:-$HOME/.mozilla/firefox/profile.proxy}"
  local NAME="${3:-$(basename "$PROFILE")}"
  # Setup firefox profile
  firefox -CreateProfile "$NAME $PROFILE"
  mkdir -p "$PROFILE"
  [ -f "$PROFILE/user.js" ] &&
    sed -e '/network.proxy.type/d' \
        -e '/network.proxy.socks/d' \
        -e '/network.proxy.socks_port/d' \
        -e '/network.proxy.socks_remote_dns/d' \
        -e '/network.proxy.socks_version/d' \
        "$PROFILE/user.js"
  echo 'user_pref("network.proxy.type",1);' >> "$PROFILE/user.js"
  echo 'user_pref("network.proxy.socks","127.0.0.1");' >> "$PROFILE/user.js"
  echo 'user_pref("network.proxy.socks_port",'$PORT');' >> "$PROFILE/user.js"
  echo 'user_pref("network.proxy.socks_remote_dns",true);' >> "$PROFILE/user.js"
  echo 'user_pref("network.proxy.socks_version",5);' >> "$PROFILE/user.js"
}

##############################
# Proxify an app using dynamic SSH tunnels & proxychains
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
  ssh_tunnel_open "$SERVER" "D$LPORT" & true &&
  proxychains "$@"
  ssh_tunnel_close "$LPORT"
}

# Proxify firefox using dynamic SSH tunnels only
ssh_proxify_ff() {
  local PROFILE="$HOME/.mozilla/firefox/profile.proxify"
  local SERVER="${1:?No server specified...}"
  local LPORT="${2:?No local port specified...}"
  shift 2
  firefox_set_proxy "$LPORT" "$PROFILE" "proxify"
  ssh_tunnel_open "$SERVER" "D$LPORT" & true &&
  firefox -P "proxify" "$@"
  ssh_tunnel_close "$LPORT"
}

##############################
# Proxify an app using tor/proxychains
ssh_torify() {
  local SERVER="${1:?No server specified...}"
  local LPORT="${2:?No local port specified...}"
  local DADDR="${3:?No tor bind address specified...}"
  local DPORT="${4:?No tor bind port specified...}"
  local CONFIG="$HOME/.proxychains/proxychains.conf"
  shift 4
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

# Proxify firefox using tor
ssh_torify_ff() {
  local SERVER="${1:?No server specified...}"
  local LPORT="${2:?No local port specified...}"
  local DADDR="${3:?No tor bind address specified...}"
  local DPORT="${4:?No tor bind port specified...}"
  local PROFILE="$HOME/.mozilla/firefox/profile.tor"
  shift 4
  # Run session
  ssh_tunnel_open "$SERVER" "L$LPORT:$DADDR:$DPORT" & true
  #~ firefox -P "$PROFILE_DIR" --no-remote
  firefox_set_proxy "$LPORT" "$PROFILE" "tor"
  firefox -P "tor"
  ssh_tunnel_close "$LPORT"
}

# Proxify flux using sshuttle (TCP only)
# https://github.com/sshuttle/sshutle.git
ssh_shuttle() {
  local SSH="$(fct_content ssh | sed 's/^\s*command // ; s/"$@"//g ; s/~/$HOME/g')"
  SSH="$(eval echo "$SSH")"
  sshuttle ${SSH:+-e "$SSH"} -r "$@"
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
# youtube-dl download
youtube() {
  youtube-dl --geo-bypass --hls-prefer-native -o "%(autonumber)s-%(title)s.%(ext)s" "$@"
}
youtube_best_mp4() {
  # see https://askubuntu.com/questions/486297/how-to-select-video-quality-from-youtube-dl/1097056#1097056
  #youtube-dl --geo-bypass -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 -o "%(autonumber)s-%(title)s.%(ext)s" "$@"
  youtube-dl --geo-bypass -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best' --merge-output-format mp4 -o "%(autonumber)s-%(title)s.%(ext)s" "$@"
}
youtube_best_not_webm() {
  youtube-dl --geo-bypass -f 'bestvideo[ext!=webm]‌​+bestaudio[ext!=webm]‌​/best[ext!=webm]' -o "%(autonumber)s-%(title)s.%(ext)s" "$@"
}
