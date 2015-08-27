#!/bin/sh

gnomeshell_replace() {
	# Ask question
	if [ $# -ne 0 ]; then
		zenity --question --title "Skip resetting Gnome display ?" --timeout=10
		[ $? -ne 1 ] || exit $?
	fi

	# Kill gnome-shell and restart it
	# This is equivalent to "alt-F2 + r"
	killall -9 gnome-shell 2>/dev/null
	gnome-shell --replace >/dev/null 2>&1 &

	# Store the date in a log
	date >> "$HOME/gnome-shell-replace.log"
}

# Execute command line when any
_PREFIX="gnomeshell_"
eval $(echo "$@" | awk 'NF>0 { print "'$_PREFIX'" $0 }')
