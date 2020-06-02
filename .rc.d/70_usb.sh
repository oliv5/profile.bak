#!/bin/sh
# USB management utils
#
# see https://www.linux.org/threads/resetting-the-usb-subsystem.10404/
#
# lsusb -t
# lspci | grep USB
#
# There are four basic USB standards. Each standard has a specific Interface type as follows:
#   1.x – Open Host Controller Interface (OHCI)
#   1.x – Universal Host Controller Interface (UHCI)
#   2.0 – Enhanced Host Controller Interface (EHCI)
#   3.0 – eXtensible Host Controller Interface (xHCI)
#
# Bus bind/unbind addresses: 
#   ex: Domain:Bus:Slot.Function
#   ex: 0000:00:1a.0
#
# $ lsusb  
#   ex: Bus 002 Device 003: ID 0fe9:9010 DVICO  
#   => device is /dev/bus/usb/002/003
#
# Note: only powered on devices are listed in the commands/folders below
#  $ lsusb
#  /dev/bus/usb/
#  /sys/bus/usb/devices
#

usb_bus_lspci() {
    lspci | awk '/USB/ {print $1}' | xargs -n 1 printf "0000:%s\n"
}

usb_bus_ls() {
    dmesg | awk '/usb usb.*SerialNumber:/ {print $6}'
}

# https://askubuntu.com/questions/645/how-do-you-reset-a-usb-device-from-the-command-line
usb_ls_dev() {
    for X in /sys/bus/usb/devices/*; do 
	echo "$X"
	cat "$X/idVendor" 2>/dev/null 
	cat "$X/idProduct" 2>/dev/null
	echo
    done
}

usb_bus_off() {
    for BUS; do
	echo -n "$BUS" | grep -E "[0-9]+:[0-9]+:1" |
	    tee /sys/bus/pci/drivers/uhci_hcd/unbind /sys/bus/pci/drivers/ohci_hcd/unbind /sys/bus/pci/drivers/ehci_hcd/unbind /sys/bus/pci/drivers/xhci_hcd/unbind 2>/dev/null
    done
}

usb_bus_on() {
    for BUS; do
	echo -n "$BUS" | grep -E "[0-9]+:[0-9]+:1" |
	    tee /sys/bus/pci/drivers/uhci_hcd/bind /sys/bus/pci/drivers/ohci_hcd/bind /sys/bus/pci/drivers/ehci_hcd/bind /sys/bus/pci/drivers/xhci_hcd/bind 2>/dev/null
    done
}

usb_bus_reset() {
    usb_bus_off "$@"
    usb_bus_on "$@"
}

usb_reset_all() {
    usb_bus_reset $(usb_bus_ls)
}
