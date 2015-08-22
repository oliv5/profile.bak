#!/bin/sh

# quick tar > gz compress/deflate
tgz() {
  if [ "${1##*.}" = "tgz" ] || [ "${1%.tar.gz}" != "$1" ]; then
    tar -xvzf "$@"
  else
    tar -cvzf "${1}.tgz" "$@"
  fi
}

# tar > gz compress
tgza() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return 1
  tar -cvzf "$ARCHIVE" "$@"
}

# gz > tar deflate
tgzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1s
  [ $# -eq 0 ] && echo "No file to process..." && return 1
  mkdir -p "$DST"
  for SRC; do
    tar -xvzf "$SRC" -C "$DST"
  done
}

# tar > gpg compress
tga(){
  local ARCHIVE="${1:?No archive to create...}"
  local KEY="${2:?No encryption key specified...}"
  shift 2
  [ $# -eq 0 ] && echo "No file to process..." && return 1
  tar -cf - "$@" | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
tgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt "$SRC" | tar -xvf -C "$DST"
  done
}
