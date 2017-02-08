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
# Move files from multiple sources while filtering extensions
# ex: EXCLUDE="temp *.bak" movefiles $DST/ $SRC1/ $SRC2/
movefiles() {
  local DST="${1?No destination specified...}"; shift
  local OPT=""; for EXT in $EXCLUDE; do OPT="${OPT:+$OPT }--exclude=$EXT"; done
  for SRC; do
    rsync -av --progress --remove-source-files --prune-empty-dirs $OPT "$SRC/" "$DST" 2>/dev/null
  done
}

# Move files from mounted drives
movefiles_mnt() {
  local MNT="${1?No mountpoint specified...}"; shift
  sudo mount "$MNT" && 
    movefiles "$@"
}
