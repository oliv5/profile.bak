#!/bin/sh

# Gunzip add
gza() {
  local SRC
  for SRC; do
    gzip -rk9 "$SRC"
  done
}

# Gunzip deflate
gzd() {
  local SRC
  for SRC; do
    gunzip -dk "$SRC"
  done
}

# Gunzip test archive
gzt() {
  local RES=0
  local SRC
  for SRC; do
    gzip -tq "$SRC" || RES=$?
  done
  return $RES
}
