#!/bin/sh

########################
# quick tar compress/deflate
ta() {
  for SRC; do
    if [ "${SRC##*.}" = "tar" ]; then
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
    tar -xvf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > gz compress/deflate
tgz() {
  for SRC; do
    if [ "${SRC##*.}" = "tgz" ] || [ "${SRC%.tar.gz}" != "$SRC" ]; then
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
    tar -xvzf "$SRC" ${DST:+-C "$DST"}
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

########################
# quick tar > bz compress/deflate
tbz() {
  for SRC; do
    if [ "${SRC##*.}" = "tbz" ] || [ "${SRC##*.}" = "tbz2" ] || [ "${SRC%.tar.bz}" != "$SRC" ] || [ "${SRC%.tar.bz2}" != "$SRC" ]; then
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
    tar -xvjf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > xz (Lzma) compress/deflate
txz() {
  for SRC; do
    if [ "${SRC##*.}" = "txz" ] || [ "${SRC%.tar.xz}" != "$SRC" ]; then
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
  tar -cvJf "$ARCHIVE" "$@"
}

# tar > xz deflate
txzd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    tar -xvJf "$SRC" ${DST:+-C "$DST"}
  done
}

########################
# quick tar > gpg compress/deflate
tgg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.tar.gpg}" != "$SRC" ]; then
      tggd "." "$SRC"
    else
      tgga "$KEY" "${SRC%%/*}.tar.gpg" "$SRC" 
    fi
  done
}

# tar > gpg compress
tgga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cf - "$@" | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > tar deflate
tggd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | tar -xvf - ${DST:+-C "$DST"}
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
  #~ for FCT in ${@:-ta tgz tbz txz}; do
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
