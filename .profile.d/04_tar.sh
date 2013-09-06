#!/bin/sh

function tgz() {
  tar -cvzf "$@"
}

function untgz() {
  tar ${2:+-C "$2"} -xvzf "$1"
}
