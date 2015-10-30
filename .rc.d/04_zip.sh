#!/bin/sh

# Quick zip compress/deflate
zipq() {
  if [ "${1##*.}" = "zip" ]; then
    zipd "" "$@"
  else
    zipa "$@"
  fi
}

# Zip compress
zipa() {
  zip "${1%.*}" "$@"
}

# Zip deflate (in place when output dir is "")
zipd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    unzip "$SRC" -d "${DST:+$DST/}${SRC%.*}"
  done
}

# Zip test archive
zipt() {
  local RES=0
  local SRC
  for SRC; do
    unzip -tq "$SRC" || RES=$?
  done
  return $RES
}
