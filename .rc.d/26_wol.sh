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
