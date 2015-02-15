#!/bin/sh

# http://www.webupd8.org/2012/10/how-to-reset-compiz-and-unity-in-ubuntu.html
unity-reset() {
(set -vx
  sudo apt-get install ccsm
  echo "Check ccsm unity plugin is enabled"
  echo "Check the profile is loaded from gconf and is based on the unity template"
  echo "Press enter"; read
  ccsm &
  echo "Still doesn't work? reset unity/compiz..."
  echo "Press enter"; read
  sudo apt-get install dconf-tools
  dconf reset -f /org/compiz/
  setsid unity
  echo "Can try compiz --replace and unity --replace"
)
}

unity-reseticons() {
  unity --reset-icons
}

unity-showconfig() {
  sudo apt-get install dconf-tools
  dconf dump /org/compiz/
}
