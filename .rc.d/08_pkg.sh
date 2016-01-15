#!/bin/sh

# Cleanup packages
pkg_clean() {
  sudo apt-get autoclean
  sudo apt-get clean
  sudo apt-get autoremove
}

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
