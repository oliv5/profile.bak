#!/bin/sh

# http://www.webupd8.org/2012/10/how-to-reset-compiz-and-unity-in-ubuntu.html
unity_reset() {
(
  local _ANSWER
  set -vx
  echo "Check ccsm unity plugin is enabled"
  echo "Check the profile is loaded from gconf and is based on the unity template"
  echo "Press enter"; read _ANSWER
  ccsm &
  echo "Still doesn't work? reset unity/compiz..."
  echo "Press enter"; read _ANSWER
  dconf reset -f /org/compiz/
  setsid unity
  echo "Can try compiz --replace and unity --replace"
)
}

unity_launcher() {
  unity --reset-icons
}

unity_showconfig() {
  dconf dump /org/compiz/
}

# Execute command line when any
_PREFIX="unity_"
eval $(echo "$@" | awk 'NF>0 { print "'$_PREFIX'" $0 }')
