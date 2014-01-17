#!/bin/sh
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# 7z < Tar compress
function 7zta() {
  for i in ${@:2}; do
    tar cf - $i | 7z a ${OPTS_7Z} -si $1.tar.7z
  done
}

# 7z > tar uncompress
function 7ztx() {
  for i in $@; do
    7z x -so $i.tar.7z | tar xf -
  done
}

# 7z compress directory
function 7zd() {
  for DIR in "$@"; do
    7z ${OPTS_7Z} "$(basename $DIR).7z" "$DIR"
  done
}

# 7z deflate and diff
function 7zdiff() {
  TMP=$(mktemp -d)
  for FILE in "$@"; do
    7z x "$FILE" -o"$TMP"
    echo -e '\nDiff:'
    diffd "$TMP" . | grep -v "Only in ."
  done
}
