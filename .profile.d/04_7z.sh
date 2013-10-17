#!/bin/sh
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# Alias
alias 7za='7z a ${OPTS_7Z}'
alias 7zx='7z x'

# 7z < Tar compress
function 7zta() {
  for i in ${@:2}; do
    tar cf - $i | 7za a ${OPTS_7Z} -si $1.tar.7z
  done
}

# 7z > tar uncompress
function 7ztx() {
  for i in $@; do
    7za x -so $i.tar.7z | tar xf -
  done
}

# 7z compress directory
function 7zd() {
  for DIR in "$@"; do
    FILE="$(basename $DIR)"
    7z a ${OPTS_7Z} "${FILE}.7z" "$DIR"
  done
}
