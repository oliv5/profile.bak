#!/bin/sh

#############################
# !! Reset nautilus settings !!
# https://askubuntu.com/questions/290074/nautilus-in-gnome-3-8-doesnt-remember-any-view-settings
nautilus_reset() {
  local _ANSWER
  echo "Reset nautilus settings. (enter/ctrl-c)"; read _ANSWER
  killall nautilus
  rm -rf ~/.config/nautilus; rm -rf ~/.config/nautilus-extensions; dconf reset -f /org/gnome/nautilus
}

##########################
##########################
# Execute command
[ $# -gt 0 ] && nautilus_"$@"
