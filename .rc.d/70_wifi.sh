#!/bin/sh

# Wifi on/off
alias wifi_on='wifi_enable'
alias wifi_off='wifi_disable'

# Wifi enable
wifi_enable() {
    sudo rfkill unblock wifi
    sudo ifconfig "${1:-wlan0}" up
    [ $# -gt 1 ] && wifi_connect "$@"
}

# Wifi disable
wifi_disable() {
    sudo ifconfig "${1:-wlan0}" down
    sudo rfkill block wifi
}

# Wifi status test
wifi_enabled() {
  ip addr show dev ${1:-wlan0} 2>/dev/null | grep UP >/dev/null
}
wifi_enabled2() {
  iw ${1:-wlan0} link 2>/dev/null | grep -v -i not >/dev/null
}

# List networks
wifi_scan() {
    sudo iwlist "${1:-wlan0}" scan
}

# Connect to network
wifi_connect() {
    sudo iwconfig "${1:-wlan0}" essid "${2:?No ESSID specified...}" ${3:+key "$3"}
    sudo dhclient "${1:-wlan0}"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#wifi}" != "$1" ] && "$@" || true
