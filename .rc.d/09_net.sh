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
ssh_aria2()       { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output specified...}"; shift 2; ssh -t $SSHOPTS -- sh -c "cd \"$DIR\"; aria2c \"$@\""; }
ssh_youtubedl()   { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; local DIR="${2:?No output specified...}"; shift 2; ssh -t $SSHOPTS -- sh -c "cd \"$DIR\"; youtubedl \"$@\""; }
ssh_top()         { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- top "$@"; }
ssh_reboot()      { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo reboot "$@"; }
ssh_shutdown()    { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo shutdown "$@"; }
ssh_cancel()      { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo shutdown -c "$@"; }
ssh_poweroff()    { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo poweroff "$@"; }
ssh_halt()        { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo halt "$@"; }
ssh_hibernate()   { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo hibernate "$@"; }
ssh_ping()        { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- ping "$@"; }
ssh_netstat()     { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo netstat "$@"; }
ssh_mount()       { local SSHOPTS="${SSHOPTS:+$SSHOPTS }${1:?No server or ssh option specified...}"; shift; ssh -t $SSHOPTS -- sudo mount "$@"; }

##############################
# Home ssh aliases examples (to be defined in .rc.local)
#alias sshh='command ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias scph='command scp -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config'
#alias rsynch='command rsync -e "ssh -i ~/private/.ssh/id_rsa -F ~/private/.ssh/config"'

# SSH command shortcuts (rely on sshh)
sshh_aria2()      { ssh(){ sshh "$@"; }; ssh_aria2 "$@"; }
sshh_youtubedl()  { ssh(){ sshh "$@"; }; ssh_youtubedl "$@"; }
sshh_top()        { ssh(){ sshh "$@"; }; ssh_top "$@"; }
sshh_reboot()     { ssh(){ sshh "$@"; }; ssh_reboot "$@"; }
sshh_shutdown()   { ssh(){ sshh "$@"; }; ssh_shutdown "$@"; }
sshh_cancel()     { ssh(){ sshh "$@"; }; ssh_cancel "$@"; }
sshh_halt()       { ssh(){ sshh "$@"; }; ssh_halt "$@"; }
sshh_hibernate()  { ssh(){ sshh "$@"; }; ssh_hibernate "$@"; }
sshh_ping()       { ssh(){ sshh "$@"; }; ssh_ping "$@"; }
sshh_netstat()    { ssh(){ sshh "$@"; }; ssh_netstat "$@"; }
sshh_mount()      { ssh(){ sshh "$@"; }; ssh_mount "$@"; }


##############################
# Ssh tunnel shortcuts
ssh_tunnel_open_local() {
  local SERVER="${1:?No server specified...}"
  local PORTS="${2:?No ports specified...}"
  local TUNNEL=""
  shift 2
  for PORT in $PORTS; do
    TUNNEL="${TUNNEL:+$TUNNEL }-L $PORT:127.0.0.1:$PORT"
  done
  ssh -fnxNT "$@" "$SERVER" $TUNNEL
}
ssh_tunnel_close() {
  pgrep -f "ssh.*-L" ${@:+\| grep "$@"} | xargs -r kill
}
ssh_tunnel_ls() {
  ps -ef | grep -E "ssh.* -L .*:.*:" | grep -v grep
}

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
