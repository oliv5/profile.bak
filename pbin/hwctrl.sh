#!/bin/sh
#
#####################################################################
# Script for optimizing battery lifetime
# This script was based on lesswatts.org recommandations.
# See: http://www.lesswatts.org/
#####################################################################
#
# v1.0      Creation     eddy33  2008/10/25 for fedora-fr.org
# v1.1      Update       oliv5   2011/08/29 for personnal use
#
#####################################################################
#. /etc/init.d/functions 

umask 077
export PATH=/usr/local/bin:$PATH

#exec=
#prog=$(basename $exec)

#####################################

# Ethernet : WOL off
wol_off()
{
  ethtool -s ${2:-eth0} wol d
}

# Ethernet : WOL on
wol_on()
{
  ethtool -s ${2:-eth0} wol g
}

# Ethernet : status
eth_status()
{
  ethtool -s ${2:-eth0}
}

# Ethernet : speed 100Mb/s
ethspeed()
{
  ethtool -s ${2:-eth0} autoneg off speed $1
}

# Ethernet : speed 100Mb/s
ethspeed_100()
{
  ethspeed 100
}

# Ethernet : speed 1000Mb/s
ethspeed_1000()
{
  ethspeed 1000
}

#####################################

# Wifi off
wifi_off()
{
  echo 1 > /sys/bus/pci/devices/*/rf_kill
}

# Wifi on
wifi_on()
{
  echo 0 > /sys/bus/pci/devices/*/rf_kill
}

# Wifi Power Save Poll
wifi_psp_on()
{
  # Interface Wifi : eth1
  iwpriv eth1 set_power 5  # ipw2100 or ipw2200
  echo 5 > /sys/bus/pci/drivers/iwl3945/*/power_level # iwl3945 
  echo 5 > /sys/bus/pci/drivers/iwl4965/*/power_level # iwl4965
}

#####################################

# Bluetooth off
bluetooth_off()
{
  hciconfig hci0 down
  rmmod hci_usb
}

# Bluetooth on
bluetooth_on()
{
  modprobe hci_usb
  hciconfig hci0 up
}

#####################################

# Multi threading optimization
cpu_scheduling_optim()
{
  echo 1 > /sys/devices/system/cpu/sched_smt_power_savings
}

cpu_scheduling_default()
{
  # Normal Multi threading
  echo 0 > /sys/devices/system/cpu/sched_smt_power_savings
}

#####################################

# Hard disk write back optimization
hd_writeback_optim()
{
  # Writeback to hard disk every 15 secondes
  echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
}

# Hard disk write back default
hd_writeback_default()
{
  # Writeback to hard disk every 5 secondes
  echo 500 > /proc/sys/vm/dirty_writeback_centisecs 
}

#####################################

# I/O Optimization
io_optim()
{
  # Laptop mode enabled for I/O
  echo 5 > /proc/sys/vm/laptop_mode
}

io_default()
{
  # Normal I/O
  echo 0 > /proc/sys/vm/laptop_mode
}

#####################################

# HAL CDROM Polling Optimization
hal_cdrom_polling_disable()
{
  # HAL CDROM polling disabled if external CDROM connected
  hal-disable-polling --device /dev/scd0
}

hal_cdrom_polling_enable()
{
  # HAL CDROM polling enabled
  hal-disable-polling --device /dev/scd0 --enable-polling
}

#####################################

profile_eco() {
    echo -n $"Apply eco profile: "
    wol_off
    wifi_off
    bluetooth_off
    cpu_scheduling_optim
    hd_writeback_optim
    io_optim
    hal_cdrom_polling_disable
    RETVAL=0
    RETVAL=$?
    echo
    return $RETVAL
}

profile_perf() {
    echo -n $"Apply performence profile: "
    # do not enable wol here
    wifi_on
    bluetooth_on
    cpu_scheduling_default
    hd_writeback_default
    io_default
    hal_cdrom_polling_enable
    RETVAL=0
    RETVAL=$?
    echo
    return $RETVAL
}

#####################################

#shopt -s nocasematch

case "$1" in
    eco|perf)
        $1
        ;;
    ethstatus)
        eth_status
        ;;
    wol)
        [ "$2" = "on" ] && wol_on "$3" || wol_off "$3"
        ;;
    wifi)
        [ "$2" = "on" ] && wifi_on || wifi_off
        ;;
    bluetooth)
        [ "$2" = "on" ] && bluetooth_on || bluetooth_off
        ;;
    scheduler)
        [ "$2" = "on" ] && cpu_scheduling_optim || cpu_scheduling_default
        ;;
    hdd)
        [ "$2" = "on" ] && hd_writeback_optim || hd_writeback_default
        ;;
    io)
        [ "$2" = "on" ] && io_optim || io_default
        ;;
    cdrom)
        [ "$2" = "on" ] && hal_cdrom_polling_enable || hal_cdrom_polling_disable
        ;;
    *)
        echo $"Usage: $0 {eco|perf|wol|wifi|bluetooth|scheduler|hdd|io|cdrom|ethstatus} {on|off}"
        return 2
        ;;
esac

