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
# IP tables flush: must be done by a script at once
iptables_flush() {
  # Set policies to ACCEPT
  sudo iptables -t filter -P INPUT ACCEPT
  sudo iptables -t filter -P FORWARD ACCEPT
  sudo iptables -t filter -P OUTPUT ACCEPT
  # Remove all existing rules
  sudo iptables -t filter -F	# All rules
  sudo iptables -t filter -X	# Delete all user defined-chains (ex: ssh established session)
  sudo iptables -t nat -F
  sudo iptables -t nat -X
  sudo iptables -t mangle -F
  sudo iptables -t mangle -X
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
