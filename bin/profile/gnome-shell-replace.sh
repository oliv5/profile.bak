#!/bin/sh
# This is equivalent to "alt-F2 + r"
if [ $# -ne 0 ]; then
	zenity --question --title "Skip resetting Gnome display ?" --timeout=10
fi
[ $? -ne 1 ] && gnome-shell --replace >/dev/null 2>&1 &
