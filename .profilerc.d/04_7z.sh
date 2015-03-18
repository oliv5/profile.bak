#!/bin/sh
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# 7z < Tar compress
_7zta() {
  local ARCHIVE="$1.tar.7z"
  local i
  shift $(min 1 $#)
  for i; do
    tar cf - "$i" | 7z a ${OPTS_7Z} -si "$ARCHIVE"
  done
}

# 7z > tar deflate
_7ztd() {
  local i
  for i; do
    7z x -so "$i.tar.7z" | tar xf -
  done
}

# 7z compress
_7za() {
  local i
  for i; do
    7z a ${OPTS_7Z} "$(basename "$i").7z" "$i"
  done
}

# 7z deflate
_7zd() {
  local i
  for i; do
    7z x "$i"
  done
}

# Extract to tmp dir
__7zd() {
  local DIR="$1"
  if [ ! -d "$1" ]; then
	  DIR="$(mktemp -d --tmpdir $(basename $1).XXXXXX)"
	  7z x "$1" -o"$DIR" 1>&2
  fi
  echo "$DIR"
}

# 7z deflate and diffd
_7zdiffd() {
  local DIR1="$(__7zd "$1")"
  local DIR2
  shift $(min 1 $#)
  for DIR2; do
    DIR2="$(__7zd "$DIR2")"
    diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and diff
_7zdiff() {
  local DIR1="$(__7zd "$1")"
  local DIR2
  shift $(min 1 $#)
  for DIR2; do
    DIR2=$(__7zd "$DIR2")
    diff -r "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
  done
}

# 7z deflate and meld
_7zdiffm() {
  local DIR1="$(__7zd "$1")"
  local DIR2 DIFFCNT
  shift $(min 1 $#)
  for DIR2; do
    DIR2="$(__7zd "$DIR2")"
    DIFFCNT=$(diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1" | wc -l)
    echo; echo "Number of diff files: $DIFFCNT"
    diffd "$DIR1" "$DIR2" | grep -v "Only in $DIR1"
    if [ $DIFFCNT -gt 0 ]; then
      meld "$DIR2" "$DIR1"
    fi
  done
}
