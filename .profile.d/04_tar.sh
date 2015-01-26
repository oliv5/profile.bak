#!/bin/sh

tgz() {
  tar -cvzf "${1%*/}.tgz" "$@"
}

untgz() {
  tar ${2:+-C "$2"} -xvzf "$1"
}
