#!/bin/sh
read -p "Hibernate (y/N) ? " __
case "$__" in
    y|Y)
	nohup gnome-screensaver-command -l
	sudo systemctl hibernate
    ;;
esac
