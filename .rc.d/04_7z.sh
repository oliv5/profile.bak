#!/bin/sh
# Note: could use "xz -9" instead of "7z x"
# Note: could use "xzdiff" for diffs

# Aliases (fct names cannot start with digits)
alias 7zq='_7z'
alias 7za='_7za'
alias 7zd='_7zd'
alias 7zg='_7zg'
alias 7zga='_7zga'
alias 7zgd='_7zgd'
alias 7zdiff='_7zdiff'
alias 7zdiffd='_7zdiffd'
alias 7zdiffm='_7zdiffm'

###############################
# quick 7z compress
_7z() {
  for SRC; do
    if [ "$SRC" != "${SRC%.7z}" ]; then
      _7zd "." "$SRC"
    else
      _7za "${SRC%%/*}.7z" "$SRC"
    fi
  done
}

# 7z compress
_7za() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off "$ARCHIVE" "$@"
}

# 7z deflate
_7zd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  for SRC; do
    7z x -o"$DST" "$SRC"
  done
}

###############################
# quick 7z > gpg compress
_7zg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.7z.gpg}" ]; then
      _7zgd "." "$SRC"
    else
      _7zga "$KEY" "${SRC%%/*}.7z.gpg" "$SRC"
    fi
  done
}

# 7z > gpg compress
_7zga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  # 7z does not support "7z a -so" with 7z compression
  #7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off -an -so "$@" | gpg --encrypt  --batch --recipient "$KEY" -o "$ARCHIVE"
  local TMP="$(mktemp --suffix=.7z -u)"
  eval 7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off "$TMP" "$SRC"
  gpg --encrypt --batch --recipient "$KEY" -o "$ARCHIVE" "$TMP"
  rm "$TMP"
}

# gpg > 7z deflate
_7zgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  for SRC; do
    # 7z does not support "7z x -si" with 7z compression
    #gpg --decrypt --batch "$SRC" | 7z x -si -o"$DST"
    local TMP="$(mktemp --suffix=.7z -u)"
    gpg --decrypt --batch -o "$TMP" "$SRC"
    7z x "$TMP" -o"$DST"
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

###############################
# Unit test
#~ _unittest _7zq '_7zg 0x95C1629C87884760'

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#7z}" != "$1" ] && "$@" || true
