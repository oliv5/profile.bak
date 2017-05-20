#!/bin/sh 
EMAIL="$1"
DIR="${2:-$(mktemp -d)}"
FILENAME="$DIR/health-$(hostname)-$(date +%y%m%d-%H%M).txt"

# Command exist check
cmd_exists() {
	for C; do
		command -v "$C" >/dev/null || return 1
	done
}

# Unlock sudo
sudo true

# Build report
cat >"$FILENAME" 2>&1 <<EOF
#####################################################################
Health Check Report (CPU, Process, Disk Usage, Memory)
#####################################################################
Hostname         : `hostname`
Distribution     : `uname -v`
Kernel Version   : `uname -r`
Uptime           : `uptime -p`
Last Reboot Time : `who -b | awk '{print $3,$4}'`


*********************************************************************
CPU Load
*********************************************************************
Load Average : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,`
Heath Status : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`
$(if cmd_exists mpstat; then mpstat -P ALL; fi)


*********************************************************************
Processes
*********************************************************************
=> Top CPU using process/application
`top b -n1 | head -17 | tail -11`

=> Top memory using processs/application
PID %MEM RSS COMMAND
`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10`


*********************************************************************
Disk Usage
*********************************************************************
$(df -Pkh | grep -v 'Filesystem')


*********************************************************************
Memory
*********************************************************************
$(free -m)


*********************************************************************
Hardware
*********************************************************************
CPU information
$(if cmd_exists lscpu; then lscpu; else echo "Not available..."; fi)


HW information
$(if cmd_exists lshw; then sudo lshw -short; else echo "Not available..."; fi)


Block devices
$(if cmd_exists lsblk; then lsblk -a; else echo "Not available..."; fi)


USB information
$(if cmd_exists lsusb; then lsusb; else echo "Not available..."; fi)


PCI information
$(if cmd_exists lspci; then lspci; else echo "Not available..."; fi)


SCSI information
$(if cmd_exists lsscsi; then lsscsi -s; else echo "Not available..."; fi)

Disk information
$(if cmd_exists hdparm; then sudo hdparm /dev/sd*; else echo "Not available..."; fi)

Disk information (2)
$(if cmd_exists fdisk; then sudo fdisk -l; else echo "Not available..."; fi)


*********************************************************************
Full system information (DMI tables)
*********************************************************************
$(if cmd_exists dmidecode; then sudo dmidecode -q; else echo "Not available..."; fi)

EOF
echo "Report written into $FILENAME"

# Send email
if [ -n "$EMAIL" ]; then
	if cmd_exists mail; then
		cat "$FILENAME" | mail -s "$FILENAME" "$EMAIL"
		echo "Email sent to $EMAIL"
	fi
fi
