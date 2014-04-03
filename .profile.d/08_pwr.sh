#!/bin/sh

function shutdown() {
  sudo $(which shutdown) -h -P ${1:-now} ${@:2}
}

function poweroff() {
  sudo $(which shutdown)
}

function reboot() {
  sudo $(which shutdown) -r ${1:-now} ${@:2}
}

function hardreboot() {
  sudo $(which reboot) -fv ${@}
}

function suspend() {
  sudo pm-suspend ${@}
}

function hibernate() {
  sudo pm-hibernate ${@}
}
