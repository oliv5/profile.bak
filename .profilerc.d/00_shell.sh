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
