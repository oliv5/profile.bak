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

__diffp() {
  true ${1:?No diff program specified} ${2:?No file 1 specified} ${3:?No file 2 specified}
  #eval $1 <(cut -b ${4:-1-} "$2")  <(cut -b ${4:-1-} "$3")
  PIPE1="$(mktemp -u)"
  PIPE2="$(mktemp -u)"
  mkfifo "$PIPE1" "$PIPE2"
  eval "$1" "$PIPE1" "$PIPE2" &
  cut -b ${4:-1-} "$2" > "$PIPE1"
  cut -b ${4:-1-} "$3" > "$PIPE2"
  rm "$PIPE1" "$PIPE2"
}

diffr() {
  __diffp diff "$@"
}

diffm() {
  __diffp meld "$@"
}

diffb() {
  true ${1:?No file 1 specified} ${2:?No file 2 specified}
  cmp -l "$1" "$2" | gawk '{printf "%08X %02X %02X\n", $1-'${3:-0}', strtonum(0$2), strtonum(0$3)}'
}
