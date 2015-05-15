#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
#
shell_quote() {
	local SEP=''
	for ARG in "$@"; do
		SQESC=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
		printf '%s' "${SEP}'${SQESC}'"
		SEP=' '
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

################################
# Shell utils (used for shifts)
min() { echo $(($1<$2?$1:$2)); }
max() { echo $(($1>$2?$1:$2)); }
lim() { max $(min $1 $3) $2; }
isint() { expr 2 "*" "$1" + 1 >/dev/null 2>&1; }

################################
# Run a command and filter stdout by another one
shell_filter_stdout() {
  { eval "$1" 2>&1 1>&3 | eval "$2" 1>&2; } 3>&1
}
