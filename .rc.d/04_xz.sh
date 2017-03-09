#!/bin/sh
# Note: diff using "xzdiff"

###############################
# Quick tar > xz compress/deflate
xzt() {
  for SRC; do
    if [ "${SRC%.tar.xz}" != "$SRC" ]; then
      echo xztd "." "$SRC"
    else
      xzta "${SRC%%/*}.tar.xz" "$SRC"
    fi
  done
}

# tar > xz compress
xzta() {
  local ARCHIVE="${1:?No archive to create...}"
  shift 1
  tar -cvf - "$@" | xz -c -9 - > "$ARCHIVE"
}

# xz > tar deflate
xztd() {
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    xz -d --stdout "$SRC" | tar -xvf - -C "$DST"
  done
}

###############################
# Quick tar > xz > gpg compress/deflate
xzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.tar.xz.gpg}" != "$SRC" ]; then
      xzgd "." "$SRC"
    else
      xzga "$KEY" "${SRC%%/*}.tar.xz.gpg" "$SRC"
    fi
  done
}

# tar > xz > gpg compress
xzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cvf - "$@" | xz -c -9 - | gpg --encrypt --batch --recipient "$KEY" > "$ARCHIVE"
}

# gpg > xz > tar deflate
xzgd(){
  local DST="${1:?No output directory specified...}"
  local SRC
  shift 1
  mkdir -p "$DST"
  for SRC; do
    gpg --decrypt --batch "$SRC" | xz -d --stdout - | tar -xvf - -C "$DST"
  done
}

###############################
#~ # Unit test
#~ _unittest() {
  #~ cd /tmp
  #~ F1="F1"
  #~ F2="F2"
  #~ echo "This is OK." > $F1
  #~ [ $# -gt 0 ] && local IFS=$'\n' || local IFS=$' \n'
  #~ for FCT in ${@:-xzt 'xzg 0x95C1629C87884760'}; do
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
