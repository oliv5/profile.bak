#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
#
shell_quote() {
	local sep=''
	for arg in "$@"; do
		sqesc=$(printf '%s\n' "${arg}" | sed -e "s/'/'\\\\''/g")
		printf '%s' "${sep}'${sqesc}'"
		sep=' '
	done
}

# Right trim shell parameters
shell_rtrim() {
	local IFS="$(printf '\n\t ')"
	local LAST="$(($#-$1))"
	for ARG in $(seq 2 $LAST); do 
		eval ARG="\${$ARG}"
		ARG=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
		printf '%s' "'${ARG}' "
	done
}

# Left trim shell parameters
shell_ltrim() {
	local IFS="$(printf '\n\t ')"
	shift $(($1+1))
	echo "$@"
}

# Trim left&right shell parameters
shell_trim() {
	eval set $(shell_rtrim $2 $(shell_ltrim $1 "$@"))
	echo "$@"
}

# Retrieve last shell parameters
shell_lastargs() {
	local IFS="$(printf '\n\t ')"
	shift $(($#-$1))
	echo "$@"
}

# Retrieve one of the last shell parameters
shell_lastarg() {
	local IFS="$(printf '\n\t ')"
	shift $(($#-$1))
	echo "$1"
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

