#!/bin/sh

# Quick zip compress/deflate
zp() {
  for SRC; do
    if [ "${SRC##*.}" = "zip" ]; then
      zpd "." "$SRC"
    else
      zpa "${SRC%%/*}.zip" "$SRC"
    fi
  done
}

# Zip compress
zpa() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  zip -r9 "$ARCHIVE" "$@"
}

# Zip deflate (in place when output dir is "")
zpd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    unzip "$SRC" -d "${DST:+$DST/}"
  done
}

# Zip test archive
zpt() {
  local RES=0
  local SRC
  for SRC; do
    unzip -tq "$SRC" || RES=$?
  done
  return $RES
}

###############################
# Quick zip > gpg compress/deflate
zpg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.zip.gpg}" != "$SRC" ]; then
      zpgd "." "$SRC"
    else
      zpga "$KEY" "${SRC%%/*}.zip.gpg" "$SRC"
    fi
  done
}

# zip > gpg compress
zpga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  zip -r9 - "$@" | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > zip deflate
zpgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | funzip > "$DST/$(basename "${SRC%.zip.gpg}")"
  done
}

###############################
# Unit test
#~ _unittest zp 'zpg 0x95C1629C87884760'
