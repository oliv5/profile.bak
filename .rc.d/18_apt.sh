#!/bin/sh

# apt/dpkg commands
alias pkg_archi='dpkg --print-architecture'
alias pkg_download='apt-get download'
alias pkg_installed='dpkg -s'
alias pkg_content='dpkg -L'
alias pkg_search='dpkg -S'
alias pkg_ls='dpkg -l'
alias pkg_lsconf='dpkg -l | grep -E ^rc'
alias pkg_cleanconf='dpkg -l | grep -E ^rc | xargs sudo apt-get purge'

# Cleanup packages
pkg_clean() {
  sudo apt-get autoclean
  sudo apt-get clean
  sudo apt-get autoremove
}

# Make deb package from source
deb_make() {
  local ARCHIVE="${1:?No input archive specified}"
  tar zxf "$ARCHIVE" "${ARCHIVE%.*}" || return 0
  cd "${ARCHIVE%.*}"
  ./configure || return 0
  dh_make -s -f "../$ARCHIVE"
  fakeroot debian/rules binary
}

# Lock/unlock packages
# https://askubuntu.com/questions/18654/how-to-prevent-updating-of-a-specific-package
dpkg_status() {
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
alias apt_lslock='sudo apt-mark showhold'
alias aptitude_lock='sudo aptitude hold'
alias aptitude_unlock='sudo aptitude unhold'

# Cleanup old kernels
kernel_ls() {
  dpkg -l 'linux-*'
}
kernel_current() {
  uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/"
}
kernel_others() {
  dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'
}
