#!/bin/sh
DIFF_EXCLUDE="\.git\|\.svn"

# Diff directories
diffd() {
  diff -rq "$@" | grep -ve $DIFF_EXCLUDE
}

# Diff tree
difft() {
  local TEMP="$(mktemp)"
  find "$1" -type d -printf "%P\n" | sort > "$TEMP"
  find "$2" -type d -printf "%P\n" | sort | diff - "$TEMP"
  rm "$TEMP"
}
difftt() {
  local TEMP="$(mktemp)"
  tree -i "$1" > "$TEMP"
  tree -i "$2" | diff - "$TEMP"
  rm "$TEMP"
}

# Count number of lines which differs
diffc() {
  diff -U 0 "$1" "$2" | grep '^+[^+]' | wc -l
}

# Count number of bloc which differs
diffbc() {
  diff -U 0 "$1" "$2" | grep '^@' | wc -l
}

# Show part of files differences
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
alias diffp='__diffp diff'
alias diffpm='__diffp meld'

# Compare files and display diffs in hexa format
diffh() {
  true ${1:?No file 1 specified} ${2:?No file 2 specified}
  cmp -l "$1" "$2" | gawk '{printf "%08X %02X %02X\n", $1-'${3:-0}', strtonum(0$2), strtonum(0$3)}'
}

# Diff using rsync
diffr() {
  rsync -avsn "$@"
}
diffrd() {
  rsync -avsn --delete "$@" | grep "^delet"
}
diffru() {
  rsync -avsn --existing "$@"
}
diffrn() {
  rsync -avsn --ignore-existing "$@"
}
