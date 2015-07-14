#!/bin/sh
# Note: diff using "xzdiff"

# Tar > xz compress
xzta() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  tar -cvf - "$@" | xz -c -9 - > "$ARCHIVE"
}

# xz > tar deflate
xztd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  mkdir -p "$DST"
  for SRC; do
    xz -d --stdout "$SRC" | tar -xvf - -C "$DST"
  done
}

# tar > xz > gpg compress
xzga(){
  local ARCHIVE="${1:?No archive to create...}"
  local KEY="${2:?No encryption key specified...}"
  shift 2
  [ $# -eq 0 ] && echo "No file to process..." && return
  tar -cvf - "$@" | xz -c -9 - | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > xz > tar deflate
xzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt "$SRC" | xz -d --stdout - | tar -xvf - -C "$DST"
  done
}
