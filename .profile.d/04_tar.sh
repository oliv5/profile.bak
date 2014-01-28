#!/bin/sh

function tgz() {
  tar -cvzf "${1%*/}.tgz" "$@"
}

function untgz() {
  tar ${2:+-C "$2"} -xvzf "$1"
}
