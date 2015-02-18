#!/bin/sh

# Put parameters into variables
getargs(){
	local VAR
	for VAR in $1; do
		eval "$VAR=$2"
		shift
	done
	eval "$VAR=\"$@\""
}

# Shift and return the remaining parameters
shiftargs() {
	shift ${1:-0}; shift
	echo "$@"
}
