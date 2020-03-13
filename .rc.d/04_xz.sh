#!/bin/sh
# Note: diff using "xzdiff"

###############################
# Quick xz compress/deflate
xzq() {
  for SRC; do
    if [ "$SRC" != "${SRC%.xz}" ]; then
      xzd "." "$SRC"
    else
      xza "${SRC%%/*}.xz" "$SRC"
    fi
  done
}

# xz compress
xza() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  command xz -zk9c "$@" > "$ARCHIVE"
}

# xz deflate
xzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  ( command cd "$DST"
    for SRC; do
      command xz -dk "$SRC"
    done
  )
}

###############################
# Quick xz > gpg compress/deflate
xzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.xz.gpg}" ]; then
      xzgd "." "$SRC"
    else
      xzga "$KEY" "${SRC%%/*}.xz.gpg" "$SRC"
    fi
  done
}

# xz > gpg compress
xzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  command xz -zk9c "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > xz deflate
xzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  ( command cd "$DST"
    for SRC; do
      gpg --decrypt --batch "$SRC" | command xz -d > "${SRC%.xz.gpg}"
    done
  )
}

###############################
# Unit test
#~ _unittest xzq 'xzg 0x95C1629C87884760'

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#xz}" != "$1" ] && "$@" || true
