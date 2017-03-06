#!/bin/sh

# Quick zip compress/deflate
zipq() {
  for SRC; do
    if [ "${SRC##*.}" = "zip" ]; then
      zipd "." "$SRC"
    else
      zipa "${SRC}.zip" "$SRC"
    fi
  done
}

# Zip compress
zipa() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  zip -r9 "$ARCHIVE" "$@"
}

# Zip deflate (in place when output dir is "")
zipd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift
  for SRC; do
    unzip "$SRC" -d "${DST:+$DST/}"
  done
}

# Zip test archive
zipt() {
  local RES=0
  local SRC
  for SRC; do
    unzip -tq "$SRC" || RES=$?
  done
  return $RES
}

###############################
# Quick tar > zip > gpg compress/deflate
zipg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.tar.xz.gpg}" != "$SRC" ]; then
      zipgd "." "$SRC"
    else
      zipga "$KEY" "${SRC}.tar.xz.gpg" "$SRC"
    fi
  done
}

# tar > zip > gpg compress
zipga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cvf - "$@" | zip -r9 - - | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > zip > tar deflate
zipgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | funzip 2>/dev/null | tar -xvf - -C "$DST"
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
  #~ for FCT in ${@:-zipq 'zipg 0x95C1629C87884760'}; do
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
