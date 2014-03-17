#!/bin/sh

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
		top -d 0.5 -b -n2 | grep "Mem:" | tail -n 1 | awk '{print ($4*100/$2)}'
	else
		top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$10}; END {print sum}'
	fi
}
