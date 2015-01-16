#!/bin/sh

# Syslog
alias syslog='sudo tail /var/log/syslog'

# Processes
alias psf='ps -faux'
alias psd='ps -ef'
alias psg='ps -ef | grep -i'
alias psu='ps -fu $USER'
alias pg='pgrep -fl'
alias pgu='pgrep -flu $(id -u $USER)'

function pid() {
	for NAME in "$@"; do
		ps -C "$@" -o pid=
	done
}

function uid() {
	for NAME in "$@"; do
		ps -C "$@" -o user=
	done
}

# System information
function sys-iostat() {
	iostat -x 2
}

function sys-stalled() {
	while true; do ps -eo state,pid,cmd | grep "^D"; echo "—-"; sleep 5; done
}

function sys-cpu() {
	sar ${1:-1} ${2}
}

function cpu-avg() {
	eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$3}; END {print sum}'"
}

function mem-avg() {
	eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$4}; END {print sum}'"
}

function cpu-inst() {
	if [ -z "$1" ]; then
		top -d 0.5 -b -n2 | grep "Cpu(s)" | tail -n 1 | awk '{print $2 + $4 + $6}'
	else
		top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$9}; END {print sum}'
	fi
}

function mem-inst() {
	if [ -z "$1" ]; then
		top -d 0.5 -b -n2 | grep "Mem:" | tail -n 1 | awk '{print ($5*100/$3)}'
	else
		top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$10}; END {print sum}'
	fi
}

function swap-inst() {
	top -d 0.5 -b -n2 | grep "Swap:" | tail -n 1 | awk '{print ($4*100/$2)}'
}

function cpu-top() {
	eval "ps aux --sort -%cpu ${1:+| head -n $(($1 + 1))}"
}

function mem-top() {
	eval "ps aux --sort -rss ${1:+| head -n $(($1 + 1))}"
}

function kill-cpu-top() {
	END=$((${1:-1} + 1))
	ps a --sort -%cpu | awk "NR>1 && NR<=$END {print \$1;}" | xargs kill ${@:2}
}

function kill-mem-top() {
	END=$((${1:-1} + 1))
	ps a --sort -rss | awk "NR>1 && NR<=$END {print \$1;}" | xargs kill ${@:2}
}

function mem-ps() {
	while read command percent rss; do
		if [[ "${command}" != "COMMAND" ]]; then 
			rss="$(bc <<< "scale=2;${rss}/1024")"
		fi
		printf "%-26s%-8s%s\n" "${command}" "${percent}" "${rss}"
	done < <(ps -A --sort -rss -o comm,pmem,rss | head -n 11)
}

# system information aliases
alias cpu='cpu-inst'
alias mem='mem-inst'
alias swap='swap-inst'

# Keyboad layout
alias keyb-list='grep ^[^#] /etc/locale.gen'
alias keyb-set='setxkbmap -layout'
alias keyb-setfr='setxkbmap -layout fr'

# Chroot
function mk-chroot(){
	SRC="/dev/${1:?Please specify the root device}"
	DST="${2:-/mnt}"
	mount "$SRC" "$DST"
	mount --bind "/dev" "$DST/dev"
	mount --bind "/dev/pts" "$DST/dev/pts"
	mount -t sysfs "/sys" "$DST/sys"
	mount -t proc "/proc" "$DST/proc"
	chroot "$DST"
}

# Make deb package from source
function make-deb() {
	ARCHIVE="${1:?No input archive specified}"
	tar zxf "$ARCHIVE" || return 0
	cd "${ARCHIVE%.*}"
	./configure || return 0
	dh_make -s -f "../$ARCHIVE"
	fakeroot debian/rules binary
}

# Install file notifier
alias write-notify='notify close_write'
alias read-notify='notify close_read'
alias rw-notify='notify "close_read,close_write"'
alias create-notify='notify create'
alias mv-notify='notify moved_to'
alias notify='_notify-file'

# Basic notification method with a loop
# Pros: file move is captured
# Cons: may miss event, high system resource consumption on large directories
function _notify-loop() {
	while true; do
		inotifywait -qq -e ${1:?Nothing to monitor} "${2:-$PWD}"
		eval ${3:-true} ${@:4}
	done
}

# Main notification method
# Pros: only a single inotifywait process & set of pipes
# Cons: does not capture file moves properly
function _notify-proc() {
	TRIGGER="${1:?No event to monitor}"
	FILE="${2:?No dir/file to monitor}"
	SCRIPT="${3:?No action to execute} ${@:4}"
	
	# Start child shell process, open pipes
	# Kill inotifywait when this process is killed
	if [ ${BASH_VERSION%%[^0-9]*} -ge 4 ]; then
		eval "
			coproc INOTIFY {
				inotifywait -q -m -e $TRIGGER \"$FILE\" &
				trap \"kill $!\" 1 2 3 6 15
				wait 
			}"
	else
		echo "This bash version \"${BASH_VERSION%%[^0-9.]*}\" does not support coproc"
	fi

	# Kill the coproc child process when father is killed or interrupted
	trap "kill $INOTIFY_PID" 0 1 2 3 6 15

	## Loop for each action
	while IFS=' ' read -ru ${INOTIFY[0]} DIR TRIGGER FILE; do # could use "read 0<&${INOTIFY[0]}"
		#echo "Event=$TRIGGER dir=$DIR file=$FILE exec=$SCRIPT"
		eval $SCRIPT
	done
	
	# Kill the coproc child process
	kill $INOTIFY_PID 2>/dev/null
}

# Main notification method enhencement to support file moves
# Monitor the root directory, filter events on file names
# Pros: uses _notify-proc low resource method
# Cons: it is triggered for every file event of the root directory
function _notify-file() {
	_notify-proc $1 "$(dirname "$2")" 'if [ "$(readlink -f "$DIR$FILE")" == "$(readlink -f "'$2'")" ]; then '${3:?No action to execute} ${@:4}'; fi'
}

# NFS unmount
alias nfs-umountall='umount -a -t nfs'
function nfs-umount() {
	sudo sh -c "
		ifconfig eth0:nfstmp ${2:?NFS IP not specified...} netmask 255.255.255.255
		umount -f -l \"${1:?NFS mount point not specified...}\"
		ifconfig eth0:nfstmp down
	"
}

# NFS remount
function nfs-remount() {
	sudo sh -c "
		ifconfig eth0:fakenfs ${2:?NFS IP not specified...} netmask 255.255.255.255
		umount -f -l \"${1:?NFS mount point not specified...}\"
		ifconfig eth0:fakenfs down
		mount \"$1\"
	"
}

# Fstab to autofs conversion
function fstab2autofs() {
	awk 'NF && substr($1,0,1)!="#" {print $2 "\t-fstype="$3 "," $4 "\t" $1}' "$@"
}

# Disable bell
# https://wiki.archlinux.org/index.php/Disable_PC_speaker_beep
function bell-off() {
	# In X
	xset -b
	# In console
	setterm -blength 0
}
