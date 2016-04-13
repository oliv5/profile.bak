#!/bin/sh

gshell_replace() {
	# Ask question
	if [ "$1" != "-s" ]; then
		if command -v zenity >/dev/null; then
			zenity --question --title "Reset Gnome display ?" --timeout=3
			[ $? -eq 1 ] && return 1
		else
			echo -n "Reset Gnome display (y/n)? "
			local ANSWER; read ANSWER
			[ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && return 1
		fi
	fi
	# Kill gnome-shell and restart it (same as "alt-F2 + r")
	killall -9 gnome-shell 2>/dev/null
	sleep 1s
	gnome-shell --replace >/dev/null 2>&1 &
	# Store the date in a log
	if [ -w "$HOME/gnome-shell-replace.log" ]; then
		date >> "$HOME/gnome-shell-replace.log"
	fi
	return 0
}

# Execute command when any
[ $# -gt 0 ] && gshell_"$@"
