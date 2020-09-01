#!/bin/sh

shutdown() {
  local WHEN="${1:-now}"; shift $(min 1 $#)
  sudo shutdown -h -P "$WHEN" "$@"
}

poweroff() {
  sudo shutdown
}

reboot() {
  local WHEN="${1:-now}"; shift $(min 1 $#)
  sudo shutdown -r "$WHEN" "$@"
}

hardreboot() {
  sudo reboot -fv "$@"
}

suspend() {
  sudo pm-suspend "$@"
}

hibernate() {
  sudo pm-hibernate "$@"
}
