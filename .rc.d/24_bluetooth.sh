#!/bin/sh

# On/off
alias bt_on='bt_enable'
alias bt_off='bt_disable'

# Install packages
bt_install() {
    sudo apt-get install bluez bluez-utils "$@"
}

# Enable
bt_enable() {
    sudo modprobe btusb
    sudo rfkill unblock bluetooth
    sudo service bluetooth start
}

# Disable
bt_disable() {
    sudo service bluetooth stop
    sudo rfkill block bluetooth
    sudo rmmod btusb
}

# Get config
bt_getconfig() {
    sudo hciconfig
    sudo hcitool dev
    sudo hcitool scan
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#bt}" != "$1" ] && "$@" || true
