#!/bin/sh
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# 7z < Tar compress
function 7zta() {
  for i in ${@:2}; do
    tar cf - $i | 7z a ${OPTS_7Z} -si $1.tar.7z
  done
}

# 7z > tar deflate
function 7ztd() {
  for i in $@; do
    7z x -so $i.tar.7z | tar xf -
  done
}

# 7z compress
function 7za() {
  for i in "$@"; do
    7z a ${OPTS_7Z} "$(basename $i).7z" "$i"
  done
}

# 7z deflate
function 7zd() {
  for i in "$@"; do
    7z x "$i"
  done
}

# Extract to tmp dir
function _7zd() {
  DIR="$1"
  if [ ! -d "$1" ]; then
	  DIR="$(mktemp -d --tmpdir $(basename $1).XXXXXX)"
	  7z x "$1" -o"$DIR" 1>&2
  fi
  echo "$DIR"
}

# 7z deflate and ddiff
function 7zddiff() {
  DIR1=$(_7zd "$1")
  for DIR2 in "${@:2}"; do
    DIR2=$(_7zd "$DIR2")
    echo -e '\nDir diff list:'
    ddiff "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and diff
function 7zdiff() {
  DIR1=$(_7zd "$1")
  for DIR2 in "${@:2}"; do
    DIR2=$(_7zd "$DIR2")
    echo -e '\nDir diff list:'
    diff -r "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and meld
function 7zdiffm() {
  DIR1=$(_7zd "$1")
  for DIR2 in "${@:2}"; do
    DIR2=$(_7zd "$DIR2")
    echo -e '\nDir diff list:'
    meld "$DIR1" "$DIR2"
  done
}
