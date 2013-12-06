#!/bin/sh

#function meld() {
#  $(which meld) "$@" &
#}

function ddiff() {
  diff -rq "$@" | grep -vE ".svn|.git"
}

function cdiff() {
  diff -U 0 "$1" "$2" | grep ^+ | wc -l
}

function cdiffb() {
  diff -U 0 "$1" "$2" | grep ^@ | wc -l
}

function rdiff() {
  true ${1:?Please specify input file 1} ${2:?Please specify input file 2} ${3:?Please specify the character range a-b} 
  diff <(cut -b $3 "$1")  <(cut -b $3 "$2")
}

function rdiffm() {
  true ${1:?Please specify input file 1} ${2:?Please specify input file 2} ${3:?Please specify the character range a-b} 
  meld <(cut -b $3 "$1")  <(cut -b $3 "$2")
}

function bdiff() {
  cmp -l ${1:?Please specify input file 1} ${2:?Please specify input file 2} | gawk '{printf "%08X %02X %02X\n", $1-'${3:-0}', strtonum(0$2), strtonum(0$3)}'
}
