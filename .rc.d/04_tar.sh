#!/bin/sh

########################
# quick tar compress/deflate
ta() {
  for SRC; do
    if [ "$SRC" != "${SRC%.tar}" ]; then
      #tar -xvf "$SRC" -C "${SRC%/*}"
      tad "." "$SRC"
    else
      #tar -cvf "${SRC}.tar" "$SRC"
      taa "${SRC%%/*}.tar" "$SRC"
    fi
  done
}

# tar
taa() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvf "$ARCHIVE" "$@"
}

# untar
tad() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvf "$SRC" -C "$DST"
  done
}

###############################
# quick tar > gpg compress/deflate
tag() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.tar.gpg}" ]; then
      tagd "." "$SRC"
    else
      taga "$KEY" "${SRC%%/*}.tar.gpg" "$SRC" 
    fi
  done
}

# tar > gpg compress
taga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cf - "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
tagd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | tar -xvf - -C "$DST"
  done
}

########################
# quick tar > gz compress/deflate
tgz() {
  for SRC; do
    if [ "$SRC" != "${SRC%.tgz}" ] || [ "$SRC" != "${SRC%.tar.gz}" ]; then
      #tar -xvzf "$SRC" -C "${SRC%/*}"
      tgzd "." "$SRC"
    else
      #tar -cvzf "${SRC}.tgz" "$SRC"
      tgza "${SRC%%/*}.tgz" "$SRC"
    fi
  done
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
    tar -xvzf "$SRC" -C "$DST"
  done
}

# tgz integrity test
tgzt() {
  local RES=0
  local SRC
  for SRC; do
    tar -tzf "$SRC" >/dev/null || RES=$?
  done
  return $RES
}

###############################
# quick tar > gz > gpg compress/deflate
tgzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.tgz.gpg}" ] || [ "$SRC" != "${SRC%.tar.gz.gpg}" ]; then
      tgzgd "." "$SRC"
    else
      tgzga "$KEY" "${SRC%%/*}.tgz.gpg" "$SRC" 
    fi
  done
}

# tar > gz > gpg compress
tgzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -czf - "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > gz > tar deflate
tgzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | tar -xvzf - -C "$DST"
  done
}

########################
# quick tar > bz compress/deflate
tbz() {
  for SRC; do
    if [ "$SRC" != "${SRC%.tbz}" ] || [ "$SRC" != "${SRC%.tbz2}" ]|| [ "$SRC" != "${SRC%.tar.bz}" ] || [ "$SRC" != "${SRC%.tar.bz2}" ]; then
      #tar -xvjf "$SRC" -C "${SRC%/*}"
      tbzd "." "$SRC"
    else
      #tar -cvjf "${SRC}.tbz" "$SRC"
      tbza "${SRC%%/*}.tbz" "$SRC"
    fi
  done
}

# tar > bz compress
tbza() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  tar -cvjf "$ARCHIVE" "$@"
}

# tar > bz deflate
tbzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvjf "$SRC" -C "$DST"
  done
}

###############################
# quick tar > bz > gpg compress/deflate
tbzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.tbz.gpg}" ] || [ "$SRC" != "${SRC%.tar.bz.gpg}" ]; then
      tbzgd "." "$SRC"
    else
      tbzga "$KEY" "${SRC%%/*}.tbz.gpg" "$SRC" 
    fi
  done
}

# tar > bz > gpg compress
tbzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cjf - "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > bz > tar deflate
tbzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | tar -xvjf - -C "$DST"
  done
}

########################
# quick tar > xz (Lzma) compress/deflate
txz() {
  for SRC; do
    if [ "$SRC" != "${SRC%.txz}" ] || [ "$SRC" != "${SRC%.tar.xz}" ]; then
      #tar -xvJf "$SRC" -C "${SRC%/*}"
      txzd "." "$SRC"
    else
      #tar -cvJf "${SRC}.txz" "$SRC"
      txza "${SRC%%/*}.txz" "$SRC"
    fi
  done
}

# tar > xz compress
txza() {
  local ARCHIVE="${1:?No archive to create...}"
  shift
  #tar -cvf - "$@" | xz -c -9 - > "$ARCHIVE"
  tar -cvJf "$ARCHIVE" "$@"
}

# tar > xz deflate
txzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    #xz -d --stdout "$SRC" | tar -xvf - -C "$DST"
    tar -xvJf "$SRC" -C "$DST"
  done
}

###############################
# Quick tar > xz > gpg compress/deflate
txzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.txz.gpg}" ]; then
      txzgd "." "$SRC"
    else
      txzga "$KEY" "${SRC%%/*}.txz.gpg" "$SRC"
    fi
  done
}

# tar > xz > gpg compress
txzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  #tar -cvf - "$@" | xz -c -9 - | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
  tar -cvJf - "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > xz > tar deflate
txzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    #gpg --decrypt --batch "$SRC" | xz -d --stdout - | tar -xvf - -C "$DST"
    gpg --decrypt --batch "$SRC" | tar -xvJf - -C "$DST"
  done
}

###############################
# quick tar > 7z compress
t7z() {
  for SRC; do
    if [ "$SRC" != "${SRC%.tar.7z}" ]; then
      t7zd "." "$SRC"
    else
      t7za "${SRC%%/*}.tar.7z" "$SRC"
    fi
  done
}

# tar > 7z compress
t7za() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  tar -cf - "$@" | 7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off -si "$ARCHIVE"
}

# 7z > tar deflate
t7zd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    7z x -so "$SRC" | tar -xf - -C "$DST"
  done
}

###############################
# quick tar > 7z > gpg compress
t7zg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "$SRC" != "${SRC%.tar.7z.gpg}" ]; then
      t7zgd "." "$SRC"
    else
      t7zga "$KEY" "${SRC%%/*}.tar.7z.gpg" "$SRC"
    fi
  done
}

# tar > 7z > gpg compress
t7zga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  # 7z does not support "7z a -so" with 7z compression
  #tar -cf - "$@" | 7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off -si -an -so "$@" | gpg --encrypt  --batch --recipient "$KEY" -o "$ARCHIVE"
  local TMP="$(mktemp --suffix=.7z -u)"
  tar -cf - "$@" | eval 7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off -si "$TMP"
  gpg --encrypt --batch --recipient "$KEY" -o "$ARCHIVE" "$TMP"
  rm "$TMP"
}

# gpg > 7z > tar deflate
t7zgd(){
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
# Unit test
#~ _unittest() {
  #~ cd /tmp
  #~ F1="F1"
  #~ F2="F2"
  #~ echo "This is OK." > $F1
  #~ [ $# -gt 0 ] && local IFS=$'\n' || local IFS=$' \n'
  #~ for FCT in "$@"; do
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
    #~ echo
  #~ done
#~ }
#~ _unittest ta 'tag 0x95C1629C87884760' tgz 'tgzg 0x95C1629C87884760' 
#~ _unittest tbz 'tbzg 0x95C1629C87884760' txz 'txzg 0x95C1629C87884760'
#~ _unittest t7z 't7zg 0x95C1629C87884760'
