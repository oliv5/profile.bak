#!/bin/sh

########################
# tar
ta() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvf "$ARCHIVE" "$@"
}

# untar
td() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > gz compress/deflate
tgz() {
  if [ "${1##*.}" = "tgz" ] || [ "${1%.tar.gz}" != "$1" ]; then
    tar -xvzf "$@"
  else
    tar -cvzf "${1%%/*}.tgz" "$@"
  fi
}

# tar > gz compress
tgza() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvzf "$ARCHIVE" "$@"
}

# gz > tar deflate
tgzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvzf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > bz compress/deflate
tbz() {
  if [ "${1##*.}" = "tbz" ] || [ "${1##*.}" = "tbz2" ] || [ "${1%.tar.bz}" != "$1" ] || [ "${1%.tar.bz2}" != "$1" ]; then
    tar -xvjf "$@"
  else
    tar -cvjf "${1%%/*}.tbz2" "$@"
  fi
}

# tar > bz compress
tba() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvjf "$ARCHIVE" "$@"
}

# tar > bz deflate
tbd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvjf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > xz (Lzma) compress/deflate
txz() {
  if [ "${1##*.}" = "txz" ] || [ "${1%.tar.xz}" != "$1" ]; then
    tar -xvJf "$@"
  else
    tar -cvJf "${1%%/*}.txz" "$@"
  fi
}

# tar > xz compress
txa() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvJf "$ARCHIVE" "$@"
}

# tar > xz deflate
txd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvJf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# tar > gpg compress
tga(){
  local ARCHIVE="${1:?No archive to create...}"
  local KEY="${2:?No encryption key specified...}"
  shift 2
  tar -cf - "$@" | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
tgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt "$SRC" | tar -xvf -C "$DST"
  done
}
