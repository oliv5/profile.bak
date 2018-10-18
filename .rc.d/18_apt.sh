#!/bin/sh

# Package management (apt/dpkg)
alias pkg_archi='dpkg --print-architecture'
alias pkg_download='apt-get download'
alias pkg_installed='dpkg -s'
alias pkg_content='dpkg -L'
alias pkg_search='dpkg -S'
alias pkg_ls='dpkg -l'
alias pkg_ls_conf='dpkg -l | grep -E ^rc'
alias pkg_clean='sudo apt-get autoclean; sudo apt-get clean; sudo apt-get autoremove'
alias pkg_clean_conf='dpkg -l | grep -E ^rc | xargs sudo apt-get purge'
alias pkg_rm_forced='sudo pkg --remove --force-remove-reinstreq'
alias pkg_rm_ppa='sudo add-apt-repository --remove'
alias pkg_search_old='apt-show-versions | grep "No available version"'
alias pkg_search_old2='aptitude search "~o"'
alias pkg_lock='dpkg_lock'
alias pkg_unlock='dpkg_unlock'
alias pkg_locked='dpkg_locked'

# Lock/unlock packages
# https://askubuntu.com/questions/18654/how-to-prevent-updating-of-a-specific-package
dpkg_locked() {
  # Install/lock/uninstall
  eval dpkg --get-selections ${1:+| grep "$1"}
}
dpkg_lock() {
  echo "${1:?No package specified...} hold" | sudo dpkg --set-selections
}
dpkg_unlock() {
  echo "${1:?No package specified...} install" | sudo dpkg --set-selections
}
alias apt_lock='sudo apt-mark hold'
alias apt_unlock='sudo apt-mark unhold'
alias apt_locked='sudo apt-mark showhold'
alias aptitude_lock='sudo aptitude hold'
alias aptitude_unlock='sudo aptitude unhold'

# Kernel management
alias kernel_ls="dpkg -l 'linux-*'"
alias kernel_current='uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/"'
alias kernel_others="dpkg -l 'linux-*' | sed '/^ii/!d;/'$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'"

# Make deb package from source
deb_make() {
  local ARCHIVE="${1:?No input archive specified}"
  tar zxf "$ARCHIVE" "${ARCHIVE%.*}" || return 0
  cd "${ARCHIVE%.*}"
  ./configure || return 0
  dh_make -s -f "../$ARCHIVE"
  fakeroot debian/rules binary
}

# Script to get all the PPA installed on a system
# https://askubuntu.com/questions/148932/how-can-i-get-a-list-of-all-repositories-and-ppas-from-the-command-line-into-an
pkg_ls_ppa() {
  for APT in `find /etc/apt/ -name \*.list`; do
      grep -Po "(?<=^deb\s).*?(?=#|$)" $APT | while read ENTRY ; do
          HOST=`echo $ENTRY | cut -d/ -f3`
          USER=`echo $ENTRY | cut -d/ -f4`
          PPA=`echo $ENTRY | cut -d/ -f5`
          #echo sudo apt-add-repository ppa:$USER/$PPA
          if [ "ppa.launchpad.net" = "$HOST" ]; then
              echo ppa:$USER/$PPA
          else
              echo \'${ENTRY}\'
          fi
      done
  done
}
