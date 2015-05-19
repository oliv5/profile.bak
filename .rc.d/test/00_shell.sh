#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
#
shell_quote() {
	local SEP=''
	local IFS="$(printf '\n\t')"
	for ARG in "$@"; do
		#ARG=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
		#printf '%s' "${SEP}'${ARG}'"
		ARG=$(printf '%s\n' "${ARG}" | awk '{if (substr($0,0,1)!="\"") {print "\""$0"\"";} else {print $0;}}')
		printf '%s' "${SEP}${ARG}"
		SEP='	'
	done
}

shell_quote() {
	local IFS="$(printf '\n\t')"
	printf '%s\n' "$@" | awk '{if (substr($0,0,1)!="\"") {print "\""$0"\"";} else {print $0;}}'
}

# Right trim shell parameters
arg_rtrim() {
	local IFS="$(printf '\n\t')"
	local LAST="$(($#-$1))"
	for ARG in $(seq 2 $LAST); do 
		eval ARG="\${$ARG}"
		ARG=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
		printf '%s' "'${ARG}'	"
	done
}

# Left trim shell parameters
shell_ltrim() {
	local IFS="$(printf '\n\t')"
	shift $(($1+1))
	#echo "$@"
	shell_quote "$@"
}

# Trim left&right shell parameters
shell_trim() {
	local IFS="$(printf '\n\t')"
	eval set $(arg_rtrim $2 $(shell_ltrim $1 "$@"))
	#echo "$@"
	shell_quote "$@"
}

# Retrieve last shell parameters
shell_lastargs() {
	local IFS="$(printf '\n\t')"
	shift $(($#-$1))
	#echo "$@"
	shell_quote "$@"
}

# Retrieve one of the last shell parameters
shell_lastarg() {
	local IFS="$(printf '\n\t')"
	shift $(($#-$1))
	#echo "$1"
	shell_quote "$@"
}

################################
# https://stackoverflow.com/questions/18186929/differences-between-login-shell-and-interactive-shell

# Returns true for interactive shells
shell_isinteractive() {
  # Test whether stdin exists
  [ -t "0" ] || [ -p /dev/stdin ]
}

# Returns true for login shells
shell_islogin() {
  # Test whether the caller name starts with a "-"
  [ "$(echo "$0" | cut -c 1)" = "-" ]
}

