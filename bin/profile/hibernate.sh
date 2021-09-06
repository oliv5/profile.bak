#!/bin/sh
read -p "Hibernate (y/N) ? " __
case "$__" in
    y|Y)
	sudo sh -c 'gnome-screensaver-command -l & systemctl hibernate 2>/dev/null'
    ;;
esac
