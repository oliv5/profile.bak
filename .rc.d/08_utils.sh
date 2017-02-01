#!/bin/sh

################################
# Ask question and expect one of the given answer
# ask_question [fd number] [question] [expected replies]
ask_question() {
  # -- Generic part --
  local REPLY
  local STDIN=/dev/fd/0
  if [ -c "/dev/fd/$1" ]; then
    STDIN=/dev/fd/$1
    shift $(min 1 $#)
  fi
  read ${1:+-p "$1"} REPLY <${STDIN}
  shift $(min 1 $#)
  # -- Custom part --
  echo "$REPLY"
  for ACK; do
    [ "$REPLY" = "$ACK" ] && return 0
  done
  return 1
}

# Ask for a file
# ask_file [fd number] [question] [file test] [default value]
ask_file() {
  # -- Generic part --
  local REPLY
  local STDIN=/dev/fd/0
  if [ -c "/dev/fd/$1" ]; then
    STDIN=/dev/fd/$1
    shift $(min 1 $#)
  fi
  read ${1:+-p "$1"} REPLY <${STDIN}
  shift $(min 1 $#)
  # -- Custom part --
  [ -z "$REPLY" ] && REPLY="$2"
  echo "$REPLY"
  test ${1:-e} "$REPLY"
}

# Get password
ask_passwd() {
  local PASSWD
  trap "stty echo; trap INT" INT; stty -echo
  read -p "${1:-Password: }" PASSWD; echo
  stty echo; trap - INT
  echo $PASSWD
}

################################
# Move files based on extensions
movefiles() {
  local SRC="${1?No source specified...}"
  local DST="${2?No destination specified...}"
  local MNT="${3?No mountpoint specified...}"
  local EXCLUDE=""
  shift 3
  for EXT; do EXCLUDE="${EXCLUDE:+$EXCLUDE }--exclude=$EXT"; done
  [ -n "$MNT" ] && sudo mount "$MNT"
  while [ -z "$MNT" ] || mountpoint "$MNT" >/dev/null; do
    rsync -av --progress --remove-source-files $EXCLUDE "$SRC" "$DST" 2>/dev/null
    echo "Waiting for file ..."
    sleep 10s
  done
}
