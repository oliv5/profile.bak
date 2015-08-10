#!/bin/sh

# apt/dpkg commands
alias pkg_download='apt-get download'
alias pkg_installed='dpkg -s'
alias pkg_content='dpkg -L'
alias pkg_search='dpkg -S'
alias pkg_list='dpkg -l'
alias pkg_archi='dpkg --print-architecture'

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
  eval dpkg --get-selections ${1:+| grep "$1"}
}
dpkg_lock() {
  echo "${1:?No package specified...} hold" | sudo dpkg --set-selections
}
dpkg_unlock() {
  echo "${1:?No package specified...} install" | sudo dpkg --set-selections
}
apt_lock(){
  sudo apt-mark hold "${1:?No package specified...}"
}
apt_unlock(){
  sudo apt-mark unhold "${1:?No package specified...}"
}
aptitude_lock(){
  sudo aptitude hold "${1:?No package specified...}"
}
aptitude_unlock(){
  sudo aptitude unhold "${1:?No package specified...}"
}
