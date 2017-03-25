#!/bin/sh
#https://doc.ubuntu-fr.org/wakeonlan

# List status
wol_status() {
    sudo ethtool ${1:-eth0} | egrep "^[[:blank:]]*Wake-on: (g|d)"
}

# Enable wol
wol_enable() {
    sudo ethtool -s ${1:-eth0} wol g
}

# Disable wol
wol_disable() {
    sudo ethtool -s ${1:-eth0} wol d
}

# Send wol packet
wol_send() {
    local MAC="${1?No MAC specified...}"
    local DST="${2?No IP address, DNS name nor network interface specified...}"
    local PORT="${3:-9}"
    local NET="${4:-wan}"
    local PASS="$5"
    MAC="${MAC//-/:}"
    if [ "$NET" = "http" ]; then
        MAC="${MAC//:/}"
        URI="https://www.depicus.com/wake-on-lan/woli?m=${MAC}&i=${DST}&s=255.255.255.255&p=${PORT}"
        #URI="http://www.wakeonlan.me/?mobile=0&ip=${DST}:${PORT}&mac=${MAC}&pass=${PASS}&schedule=&timezone=0"
        if command -v curl >/dev/null 2>&1; then
          curl "${URI}" >/dev/null
        elif command -v wget >/dev/null 2>&1; then
          wget "${URI}" -q -O /dev/null
        else
          echo "No appropriate WOL software available..."
        fi
    else
        if command -v wakeonlan >/dev/null 2>&1; then
          wakeonlan -i ${DST} -p ${PORT} ${MAC}
        elif command -v wol >/dev/null 2>&1; then
          wol -i ${DST} -p ${PORT} ${MAC}
        elif command -v etherwake >/dev/null 2>&1; then
          etherwake -i ${DST} -b ${MAC}
        else
          echo "No appropriate WOL software available..."
        fi
    fi
}

# enable wol persistently
wol_persistent() {
    sudo sh -c 'cat > /etc/init/wol <<EOF
start on started network

script
    for interface in \$(cut -d: -f1 /proc/net/dev | tail -n +3); do
        logger -t "wakeonlan init script" enabling wake on lan for \$interface
        ethtool -s \$interface wol g
    done
end script
EOF
'
}
