#!/bin/sh

# Quick gzip compress/deflate
gz() {
  for SRC; do
    if [ "${SRC##*.}" = "gz" ]; then
      gzd "." "$SRC"
    else
      gza "${SRC%%/*}.gz" "$SRC"
    fi
  done
}

# gzip add
gza() {
  local SRC
  for SRC; do
    gzip -rk9 "$SRC"
  done
}

# gzip deflate
gzd() {
  local SRC
  for SRC; do
    gunzip -dk "$SRC"
  done
}

# gzip test archive
gzt() {
  local RES=0
  local SRC
  for SRC; do
    gzip -tq "$SRC" || RES=$?
  done
  return $RES
}

###############################
# Quick tar > gzip > gpg compress/deflate
gzg() {
  local KEY="${1:?No encryption key specified...}"
  shift
  for SRC; do
    if [ "${SRC%.tar.gz.gpg}" != "$SRC" ]; then
      gzgd "." "$SRC"
    else
      gzga "$KEY" "${SRC%%/*}.tar.gz.gpg" "$SRC"
    fi
  done
}

# tar > gzip > gpg compress
gzga(){
  local KEY="${1:?No encryption key specified...}"
  local ARCHIVE="${2:?No archive to create...}"
  shift 2
  tar -cvf - "$@" | zip -r9 - - | gpg --encrypt --recipient "$KEY" > "$ARCHIVE"
}

# gpg > gzip > tar deflate
gzgd(){
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
  #~ for FCT in ${@:-gz 'gzg 0x95C1629C87884760'}; do
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
#~ _unittest
