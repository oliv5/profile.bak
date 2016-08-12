#!/bin/sh

#############################
# !! Reset unity settings !!
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

#############################
# Show unity configuration
unity_showconfig() {
  dconf dump /org/compiz/
}

#############################
# Setup unity scopes to a full offline mode
# http://www.webupd8.org/2013/10/how-to-disable-amazon-shopping.html
unity_setup_scopes() {
  # Remove shopping scope
  sudo apt-get remove unity-lens-shopping
  # Disable on-line sugestions
  gsettings set com.canonical.Unity.Lenses disabled-scopes "['more_suggestions-amazon.scope', 'more_suggestions-u1ms.scope', 'more_suggestions-populartracks.scope', 'music-musicstore.scope', 'more_suggestions-ebay.scope', 'more_suggestions-ubuntushop.scope', 'more_suggestions-skimlinks.scope']"
}

#############################
# Launcher reset
unity_launcher_reset() {
  unity --reset-icons
}

# Launcher position
alias unity_launcher_left='unity_launcher_pos Left'
alias unity_launcher_bottom='unity_launcher_pos Bottom'
alias unity_launcher_top='unity_launcher_pos Top'
alias unity_launcher_right='unity_launcher_pos Right'
unity_launcher_pos() {
  gsettings set com.canonical.Unity.Launcher launcher-position "${1:-Left}"
}

##########################
##########################
# Execute command
[ $# -gt 0 ] && unity_"$@"
