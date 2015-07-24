#!/bin/sh
# Script dependencies
rc_sourcemod "shell fct diff"

# Note: could use "xz -9" instead of "7z x"
# Note: could use "xzdiff" for diffs
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# Aliases (fct names cannot start with digits)
alias 7zta='_7zta'
alias 7ztd='_7ztd'
alias 7za='_7za'
alias 7zd='_7zd'
alias 7zga='_7zga'
alias 7zgd='_7zgd'
alias 7zdiff='_7zdiff'
alias 7zdiffd='_7zdiffd'
alias 7zdiffm='_7zdiffm'

###############################

# 7z compress
_7za() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  7z a ${OPTS_7Z} "$ARCHIVE" "$@"
}

# 7z deflate
_7zd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  for SRC; do
    7z x -o"$DST" "$SRC"
  done
}

# Tar > 7z compress
_7zta() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  tar -cf - "$@" | 7z a ${OPTS_7Z} -si "$ARCHIVE"
}

# 7z > tar deflate
_7ztd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  mkdir -p "$DST"
  for SRC; do
    7z x -so "$SRC" | tar -xf -C "$DST"
  done
}

# 7z > gpg compress
_7zga(){
  local ARCHIVE="${1:?No archive to create...}"
  local KEY="${2:?No encryption key specified...}"
  shift 2
  [ $# -eq 0 ] && echo "No file to process..." && return
  7z a ${OPTS_7Z} -an -so "$@" | gpg --encrypt --recipient "$KEY" -o "$ARCHIVE"
}

# gpg > 7z deflate
_7zgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  for SRC; do
    TMP="$(mktemp)"
    chmod 600 "$TMP"
    gpg --decrypt --batch -o "$TMP" "$SRC"
    7z x "$TMP" -o"$DST"
    rm "$TMP"
  done
}

# tar > 7z > gpg compress
_7ztga(){
  local ARCHIVE="${1:?No archive to create...}"
  local KEY="${2:?No encryption key specified...}"
  shift 2
  [ $# -eq 0 ] && echo "No file to process..." && return
  tar -cf - "$@" | 7z a ${OPTS_7Z} -si -an -so "$@" | gpg --encrypt --recipient "$KEY" -o "$ARCHIVE"
}

# gpg > 7z > tar deflate
_7ztgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  [ $# -eq 0 ] && echo "No file to process..." && return
  for SRC; do
    TMP="$(mktemp)"
    chmod 600 "$TMP"
    gpg --decrypt --batch -o "$TMP" "$SRC"
    7z x -so "$TMP" | tar -xf -C "$DST"
    rm "$TMP"
  done
}

###############################

# Extract to tmp dir
_7zdtmp() {
  local DIR="$1"
  if [ ! -d "$1" ]; then
	  DIR="$(mktemp -d --tmpdir $(basename $1).XXXXXX)"
	  7z x "$1" -o"$DIR" 1>&2
  fi
  echo "$DIR"
}

# 7z deflate and diffd
_7zdiffd() {
  local DIR1="$(_7zdtmp "${1:?Missing archive...}")"
  local DIR2
  shift $(min 1 $#)
  for DIR2; do
    DIR2="$(_7zdtmp "$DIR2")"
    diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and diff
_7zdiff() {
  local DIR1="$(_7zdtmp "${1:?Missing archive...}")"
  local DIR2
  shift $(min 1 $#)
  for DIR2; do
    DIR2=$(_7zdtmp "$DIR2")
    diff -r "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and meld
_7zdiffm() {
  local DIR1="$(_7zdtmp "${1:?Missing archive...}")"
  local DIR2 DIFFCNT
  shift $(min 1 $#)
  for DIR2; do
    DIR2="$(_7zdtmp "$DIR2")"
    DIFFCNT=$(diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1" | wc -l)
    echo; echo "Number of diff files: $DIFFCNT"
    diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
    if [ $DIFFCNT -gt 0 ]; then
      meld "$DIR2" "$DIR1"
    fi
  done
}
