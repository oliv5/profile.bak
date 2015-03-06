#!/bin/sh
DIFF_EXCLUDE="\.git\|\.svn"

diffd() {
  diff -rq "$@" | grep -ve $DIFF_EXCLUDE
}

diffc() {
  diff -U 0 "$1" "$2" | grep ^+ | wc -l
}

diffbc() {
  diff -U 0 "$1" "$2" | grep ^@ | wc -l
}

diffr() {
  true ${1:?Please specify input file 1} ${2:?Please specify input file 2} ${3:?Please specify the character range a-b}
  diff <(cut -b $3 "$1")  <(cut -b $3 "$2")
}

diffrm() {
  true ${1:?Please specify input file 1} ${2:?Please specify input file 2} ${3:?Please specify the character range a-b}
  meld <(cut -b $3 "$1")  <(cut -b $3 "$2")
}

diffb() {
  true ${1:?Please specify input file 1} ${2:?Please specify input file 2}
  cmp -l "$1" "$2" | gawk '{printf "%08X %02X %02X\n", $1-'${3:-0}', strtonum(0$2), strtonum(0$3)}'
}
