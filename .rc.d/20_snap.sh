#!/bin/sh

################################
# Remove disabled snap
# https://www.linuxuprising.com/2019/04/how-to-remove-old-snap-versions-to-free.html
snap_rm_disabled() {
  set -eu
  LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
      snap remove "$snapname" --revision="$revision"
    done
}

# Set number of retained snap versions of a package
snap_set_num_retained() {
  sudo snap set system refresh.retain="${1:-2}"
}
