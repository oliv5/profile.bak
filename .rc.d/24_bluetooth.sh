#!/bin/sh

# Bluetooth on/off
alias bt_on='bt_enable'
alias bt_off='bt_disable'

# Bluetooth enable
bt_enable() {
    rfkill unblock bluetooth
}

# Bluetooth disable
bt_disable() {
    rfkill block bluetooth
}
