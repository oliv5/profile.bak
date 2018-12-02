#!/bin/sh
# Ubuntu packages: blueman bluez bluez-utils

# On/off
alias bt_on='bt_enable'
alias bt_off='bt_disable'

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

# Reset
bt_reset() {
    bt_disable
    bt_enable
    for device in $(bt_getdevices); do
        sudo hciconfig "$device" down
        sudo hciconfig "$device" reset
        sudo hciconfig "$device" up
    done
}

# Get HCI device
bt_getdevices() {
    sudo hciconfig | awk -F':' '/^\w/{print $1}'
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
