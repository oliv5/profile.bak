#!/bin/sh

shutdown() {
  sudo $(which shutdown) -h -P ${1:-now} ${@:2}
}

poweroff() {
  sudo $(which shutdown)
}

reboot() {
  sudo $(which shutdown) -r ${1:-now} ${@:2}
}

hardreboot() {
  sudo $(which reboot) -fv ${@}
}

suspend() {
  sudo pm-suspend ${@}
}

hibernate() {
  sudo pm-hibernate ${@}
}
