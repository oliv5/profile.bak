#!/bin/sh
# Note: could use "xz -9" instead of "7z x"
# Note: could use "xzdiff" for diffs
export OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"

# Aliases (fct names cannot start with digits)
alias 7zq='_7zq'
alias 7za='_7za'
alias 7zd='_7zd'
alias 7zt='_7zt'
alias 7zta='_7zta'
alias 7ztd='_7ztd'
alias 7zg='_7zg'
alias 7zga='_7zga'
alias 7zgd='_7zgd'
alias 7ztg='_7ztg'
alias 7ztga='_7ztga'
alias 7ztgd='_7ztgd'
alias 7zdiff='_7zdiff'
alias 7zdiffd='_7zdiffd'
alias 7zdiffm='_7zdiffm'

###############################
# quick 7z compress
_7zq() {
  for SRC; do
    if [ "${SRC##*.}" = "7z" ]; then
      _7zd "." "$SRC"
    else
      _7za "${SRC%%/*}.7z" "$SRC"
    fi
  done
}

# 7z compress
_7za() {
  local IFS=$' \n' # otherwise ${OPTS_7Z} is not interpreted correctly
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  7z a ${OPTS_7Z} "$ARCHIVE" "$@"
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
# quick tar > 7z compress
_7zt() {
  for SRC; do
    if [ "${SRC%.tar.7z}" != "$SRC" ]; then
      _7ztd "." "$SRC"
    else
      _7zta "${SRC%%/*}.tar.7z" "$SRC"
    fi
  done
}

# Tar > 7z compress
_7zta() {
  local IFS=$' \n' # otherwise ${OPTS_7Z} is not interpreted correctly
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  tar -cf - "$@" | 7z a ${OPTS_7Z} -si "$ARCHIVE"
}

# 7z > tar deflate
_7ztd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    7z x -so "$SRC" | tar -xf - -C "$DST"
  done
}

###############################
# quick 7z > gpg compress
_7zg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.7z.gpg}" != "$SRC" ]; then
      _7zgd "." "$SRC"
    else
      _7zga "$KEY" "${SRC%%/*}.7z.gpg" "$SRC"
    fi
  done
}

# 7z > gpg compress
_7zga(){
  local IFS=$' \n' # otherwise ${OPTS_7Z} is not interpreted correctly
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  # 7z does not support "7z a -so" with 7z compression
  #7z a ${OPTS_7Z} -an -so "$@" | gpg --encrypt  --batch --recipient "$KEY" -o "$ARCHIVE"
  local TMP="$(mktemp --suffix=.7z -u)"
  eval 7z a ${OPTS_7Z} "$TMP" "$SRC"
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
# quick tar > 7z > gpg compress
_7ztg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.tar.7z.gpg}" != "$SRC" ]; then
      _7ztgd "." "$SRC"
    else
      _7ztga "$KEY" "${SRC%%/*}.tar.7z.gpg" "$SRC"
    fi
  done
}

# tar > 7z > gpg compress
_7ztga(){
  local IFS=$' \n' # otherwise ${OPTS_7Z} is not interpreted correctly
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  # 7z does not support "7z a -so" with 7z compression
  #tar -cf - "$@" | 7z a ${OPTS_7Z} -si -an -so "$@" | gpg --encrypt  --batch --recipient "$KEY" -o "$ARCHIVE"
  local TMP="$(mktemp --suffix=.7z -u)"
  tar -cf - "$@" | eval 7z a ${OPTS_7Z} -si "$TMP"
  gpg --encrypt --batch --recipient "$KEY" -o "$ARCHIVE" "$TMP"
  rm "$TMP"
}

# gpg > 7z > tar deflate
_7ztgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  for SRC; do
    local TMP="$(mktemp --suffix=.7z -u)"
    gpg --decrypt --batch -o "$TMP" "$SRC"
    7z x -so "$TMP" | tar -xf - -C "$DST"
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

#~ ###############################
#~ # Unit test
#~ _unittest() {
  #~ cd /tmp
  #~ F1="F1"
  #~ F2="F2"
  #~ echo "This is OK." > $F1
  #~ [ $# -gt 0 ] && local IFS=$'\n' || local IFS=$' \n'
  #~ for FCT in ${@:-_7zq _7zt '_7zg 0x95C1629C87884760' '_7ztg 0x95C1629C87884760'}; do
    #~ echo "***********************"
    #~ echo "Testing $FCT..."
    #~ rm ${F2}* 2>/dev/null
    #~ cp $F1 $F2
    #~ (set -vx; eval $FCT $F2)
    #~ diff -s $F1 $F2
    #~ ls ${F2}*
    #~ rm $F2
    #~ (set -vx; eval $FCT ${F2}.*)
    #~ diff -s $F1 $F2 &&
      #~ echo ">>>>> $FCT test success !!! <<<<<" ||
      #~ echo ">>>>> $FCT test FAILED !!! <<<<<" 
    #~ read
    #~ ls ${F2}*
    #~ rm ${F2}* 2>/dev/null
  #~ done
  #~ echo
#~ }
