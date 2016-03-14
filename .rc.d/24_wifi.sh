#!/bin/sh

# Wifi on/off
alias bt_on='wifi_enable'
alias bt_off='wifi_disable'

# Wifi enable
wifi_enable() {
    sudo ifconfig "${1:-wlan0}" up
    wifi_connect "$@"
}

# Wifi disable
wifi_disable() {
    sudo ifconfig "${1:-wlan0}" down
}

# List networks
wifi_list() {
    sudo iwlist "${1:-wlan0}" scan
}

# Connect to network
wifi_connect() {
    sudo iwconfig "${1:-wlan0}" essid "${2:?No ESSID specified...}" ${3:+key "$3"}
    sudo dhclient "${1:-wlan0}"
}
