#!/bin/sh

shutdown() {
  local WHEN="${1:-now}"; shift $(min 1 $#)
  sudo $(which shutdown) -h -P "$WHEN" "$@"
}

poweroff() {
  sudo $(which shutdown)
}

reboot() {
  local WHEN="${1:-now}"; shift $(min 1 $#)
  sudo $(which shutdown) -r "$WHEN" "$@"
}

hardreboot() {
  sudo $(which reboot) -fv "$@"
}

suspend() {
  sudo pm-suspend "$@"
}

hibernate() {
  sudo pm-hibernate "$@"
}
