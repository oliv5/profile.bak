#!/bin/sh

#function meld() {
#  $(which meld) "$@" &
#}

alias rdiff='ddiff'
function ddiff() {
  diff -rq "$@" | grep -vE ".svn|.git"
}

function cdiff() {
  diff -U 0 "$1" "$2" | grep ^@ | wc -l
}

function qdiff() {
  if [ $(cdiff "$1" "$2") -gt 10 ]; then
    meld "$@"
  else
    diff "$@"
  fi
}
