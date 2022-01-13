#!/bin/sh

###########################################
# Generic glob/regex command line management
_fregex() {
  echo "$1" | sed -Ee 's/(\()?(\|)?\*\.(\|)?(\))?/\1\2.*\\.\3\4/g ; s;//;/;g' ${2:+-e "$2"}
}
_fglob() {
  # $1=txt $2=prefix $3=delimitor
  echo "${2}${1}" | sed "s@|@${3}${2}@g ; s/(\|)//g"
}

###########################################
# Find files implementations
_ffind2() { # support regex in filename only
  local FCASE="${FCASE:--}regex"
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  shift 2>/dev/null
  ( set -f; FILES="$(_fregex $FILES)"
    find ${FOPTS} "${DIR:-.}" -regextype posix-extended -nowarn ${FTYPE:+-type $FTYPE} ${FXTYPE:+-xtype $FXTYPE} ${FILES:+$FCASE ".*/($FILES)"} ${FARGS} "$@")
}
_ffind3() { # support regex in path; slower (3 sed)
  local FCASE="${FCASE:--}regex"
  local ROOT="$(echo "$1" | sed -r -e 's;[^/]*$;;g' -e 's;[^/]*\*.*$;;g')"
  local DIR="${1#$ROOT}"; DIR="${DIR%"${1##*/}"}"
  local FILES="${1##*/}"
  local REGEX="$DIR/($(_fregex "$FILES"))"
  shift 2>/dev/null
  find ${FOPTS} "${ROOT:-.}" -regextype posix-extended -nowarn ${FTYPE:+-type $FTYPE} ${FXTYPE:+-xtype $FXTYPE} ${FILES:+$FCASE ".*$REGEX"} ${FARGS} "$@"
}
#~ _ffind_test() {
  #~ cd $(mktemp -d)
  #~ mkdir -p a/b/c
  #~ touch a/b/c/toto.txt a/b/c/toto.txt2
  #~ echo "Test"; _ffind "toto.txt"
  #~ echo "Test"; _ffind "./toto.txt"
  #~ echo "Test"; _ffind "./a*/toto.txt"
  #~ echo "Test"; _ffind "./a*/*b/toto.txt"
  #~ echo "Test"; _ffind "toto.*"
  #~ echo "Test"; _ffind "./toto.*"
  #~ echo "Test"; _ffind "./a*/toto.*"
  #~ echo "Test"; _ffind "./a*/*b/toto.*"
  #~ rm a/b/c/toto.txt a/b/c/toto.txt2
  #~ rmdir -p a/b/c
#~ }
_ffind() { _ffind3 "$@"; }
unset FCASE FTYPE FXTYPE FARGS FOPTS
alias      ff='FCASE=   FTYPE=  FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias     fff='FCASE=   FTYPE=f FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias    ffff='FCASE=   FTYPE=f FXTYPE=f FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias     ffd='FCASE=   FTYPE=d FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias     ffl='FCASE=   FTYPE=l FXTYPE=  FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias    fflf='FCASE=   FTYPE=l FXTYPE=f FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias    fflb='FCASE=   FTYPE=l FXTYPE=l FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias     iff='FCASE=-i FTYPE=  FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias    ifff='FCASE=-i FTYPE=f FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias   iffff='FCASE=-i FTYPE=f FXTYPE=f FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias    iffd='FCASE=-i FTYPE=d FXTYPE=  FOPTS="-L ${FOPTS}" FARGS="${FARGS}" _ffind'
alias    iffl='FCASE=-i FTYPE=l FXTYPE=  FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias   ifflf='FCASE=-i FTYPE=l FXTYPE=f FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias   ifflb='FCASE=-i FTYPE=l FXTYPE=l FOPTS="${FOPTS}"    FARGS="${FARGS}" _ffind'
alias    ff0='FARGS=-print0 ff'
alias   fff0='FARGS=-print0 fff'
alias  ffff0='FARGS=-print0 ffff'
alias   ffd0='FARGS=-print0 ffd'
alias   ffl0='FARGS=-print0 ffl'
alias  fflf0='FARGS=-print0 fflf'
alias  fflb0='FARGS=-print0 fflb'
alias   iff0='FARGS=-print0 iff'
alias  ifff0='FARGS=-print0 ifff'
alias iffff0='FARGS=-print0 iffff'
alias  iffd0='FARGS=-print0 iffd'
alias  iffl0='FARGS=-print0 iffl'
alias ifflf0='FARGS=-print0 ifflf'
alias ifflb0='FARGS=-print0 ifflb'
alias     ffs='ff    2>/dev/null'
alias    fffs='fff   2>/dev/null'
alias   ffffs='ffff  2>/dev/null'
alias    ffds='ffd   2>/dev/null'
alias    ffls='ffl   2>/dev/null'
alias   fflfs='fflf  2>/dev/null'
alias   fflbs='fflb  2>/dev/null'
alias    iffs='iff   2>/dev/null'
alias   ifffs='ifff  2>/dev/null'
alias  iffffs='iffff 2>/dev/null'
alias   iffds='iffd  2>/dev/null'
alias   iffls='iffl  2>/dev/null'
alias  ifflfs='ifflf 2>/dev/null'
alias  ifflbs='ifflb 2>/dev/null'
alias    ff1='FARGS="-maxdepth 1" ff'
alias   fff1='FARGS="-maxdepth 1" fff'
alias  ffff1='FARGS="-maxdepth 1" ffff'
alias   ffd1='FARGS="-maxdepth 1" ffd'
alias   ffl1='FARGS="-maxdepth 1" ffl'
alias  fflf1='FARGS="-maxdepth 1" fflf'
alias  fflb1='FARGS="-maxdepth 1" fflb'
alias   iff1='FARGS="-maxdepth 1" iff'
alias  ifff1='FARGS="-maxdepth 1" ifff'
alias iffff1='FARGS="-maxdepth 1" iffff'
alias  iffd1='FARGS="-maxdepth 1" iffd'
alias  iffl1='FARGS="-maxdepth 1" iffl'
alias ifflf1='FARGS="-maxdepth 1" ifflf'
alias ifflb1='FARGS="-maxdepth 1" ifflb'
alias    ff2='FARGS="-maxdepth 2" ff'
alias   fff2='FARGS="-maxdepth 2" fff'
alias  ffff2='FARGS="-maxdepth 2" ffff'
alias   ffd2='FARGS="-maxdepth 2" ffd'
alias   ffl2='FARGS="-maxdepth 2" ffl'
alias  fflf2='FARGS="-maxdepth 2" fflf'
alias  fflb2='FARGS="-maxdepth 2" fflb'
alias   iff2='FARGS="-maxdepth 2" iff'
alias  ifff2='FARGS="-maxdepth 2" ifff'
alias iffff2='FARGS="-maxdepth 2" iffff'
alias  iffd2='FARGS="-maxdepth 2" iffd'
alias  iffl2='FARGS="-maxdepth 2" iffl'
alias ifflf2='FARGS="-maxdepth 2" ifflf'
alias ifflb2='FARGS="-maxdepth 2" ifflb'

###########################################
# Backward find
_bfind1() {
  local ABSPATH="$(readlink -f "${1:-$PWD}")"
  local FILES="${ABSPATH##*/}"
  local DIR="${ABSPATH%$FILES}"
  DIR="${DIR:-.}"
  local FIRSTMATCH="$2"
  local FOUND=""
  while true; do
    #if eval test ${BTYPE:--e} "\"$DIR/$FILES\""; then 
    if test ${BTYPE:--e} "$DIR/$FILES"; then 
      FOUND="$DIR"
      [ ! -z "$FIRSTMATCH" ] && break
    fi
    [ -z "$DIR" -o "$DIR" == "." ] && break
    DIR="${DIR%/*}"
  done
  echo "$FOUND"
}
alias _bfind='_bfind1'
alias  bff='BTYPE=   _bfind'
alias bfff='BTYPE=-f _bfind'
alias bffd='BTYPE=-d _bfind'

###########################################
# Find breadth-first (width-first)
#_wfind1() { _ffind "${@:-*}" -prune -printf '%d\t%p\n' | sort -nk1 | cut -f2-; }
alias   wff='FARGS=-depth ff'
alias  wfff='FARGS=-depth fff'
alias  wffd='FARGS=-depth ffd'
alias  wffl='FARGS=-depth ffl'
alias wfflf='FARGS=-depth fflf'
alias wfflb='FARGS=-depth fflb'

###########################################
# File grep implementations
_fgrep1() { # Can be faster than grep -r when selecting files
  if [ $# -gt 1 ]; then
    local ARGS="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  else
    local ARGS="$1"; shift $#
  fi
  (set -f; _ffind2 "${@:-}" -type f -print0 | eval xargs -0 grep -nH --color ${GCASE} ${GARGS} -e "${ARGS:-''}")
}
_fgrep2() {
  if [ $# -gt 1 ]; then
    local ARGS="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  else
    local ARGS="$1"; shift $#
  fi
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  FILES="$(echo "${FILES}" | sed -e 's/|/ --include=/g')"
  (set -f; eval grep -RnH --color ${GCASE} ${GARGS} -e "$ARGS" ${FILES:+--include="$FILES"} "${DIR:-.}")
}
_fgrep() { _fgrep2 "$@"; }
unset GCASE GARGS
alias    gg='FCASE= FTYPE= FXTYPE= FOPTS=-L FARGS= GCASE=   GARGS=   _fgrep'
alias   igg='FCASE= FTYPE= FXTYPE= FOPTS=-L FARGS= GCASE=-i GARGS=   _fgrep'
alias   ggl='FCASE= FTYPE= FXTYPE= FOPTS=   FARGS= GCASE=   GARGS=-l _fgrep'
alias  iggl='FCASE= FTYPE= FXTYPE= FOPTS=   FARGS= GCASE=-i GARGS=-l _fgrep'
alias   ggs='gg   2>/dev/null'
alias  iggs='igg  2>/dev/null'
alias  ggls='ggl  2>/dev/null'
alias iggls='iggl 2>/dev/null'

# Alias to cut part of search result
alias c1='cut -d: -f 1'
alias c2='cut -d: -f 2'
alias c3='cut -d: -f 3'

###########################################
# Interactive search & replace
_fsed() {
  # Get arguments
  #local SEDOPT="$(arg_rtrim 3 "$@")"; shift $(($#-3))
  #local SEDOPT="--follow-symlinks"; [ $# -gt 3 ] && SEDOPT="${SEDOPT:+$SEDOPT }$1" && shift 1
  local SEDOPT=""; [ $# -gt 3 ] && SEDOPT="$1" && shift 1
  local IN="$1"; local OUT="$2"; local FILES="${SFILES:-$3}"
  # Ask for options
  local _SHOW="" _BACKUP="" _CONFIRM=""
  if [ -z "$SNOCONFIRM" ]; then
    echo "Replace '$IN' by '$OUT' in files '$FILES' ${SEDOPT:+with options $SEDOPT}"
    read -p "Show each line changed ? (Y/n) " _SHOW
    read -p "Backup each file ? (Y/n) " _BACKUP
    read -p "Confirm each file change ? (Y/n) " _CONFIRM
    [ "$_SHOW" != "n" -a "$_SHOW" != "N" ] && _SHOW=1 || unset _SHOW
    [ "$_CONFIRM" != "n" -a "$_CONFIRM" != "N" ] && _CONFIRM=1 || unset _CONFIRM
    [ "$_BACKUP" != "n" -a "$_BACKUP" != "N" ] && _BACKUP=".$(date +%Y%m%d-%H%M%S).bak" || unset _BACKUP
  fi
  # Call find and sed
  _ffind "$FILES" ${SEXCLUDE} -type f \
    ${_CONFIRM:+-exec sh -c 'read -p "Processing file {} ? (enter/ctrl-c)" DUMMY' \;} \
    ${_BACKUP:+-execdir sh -c "grep '$IN' '{}' >/dev/null" \;} \
    -execdir sed ${SEDOPT} --in-place${_BACKUP:+=$_BACKUP} ${_SHOW:+-e "\|$IN|{w /dev/stderr" -e "}"} -e "s|$IN|$OUT|g" "{}" \;
}
unset SFILES SEXCLUDE SNOCONFIRM
alias   hh='FCASE=   FTYPE= FXTYPE= FOPTS= FARGS= SFILES= SEXCLUDE= _fsed'
alias  ihh='FCASE=-i FTYPE= FXTYPE= FOPTS= FARGS= SFILES= SEXCLUDE= _fsed'

###########################################
# Find duplicate files in directory
# Does not handle filenames with \n inside
alias ff_dup='find_duplicates'
find_duplicates() {
  local TMP1="$(mktemp)"
  local TMP2="$(mktemp)"
  for DIR in "${@:-.}"; do
    find "${DIR:-.}" \( -type f -o -type l \) -exec md5sum "{}" \; | sed -e 's/^\\//' >> "$TMP1"
  done
  #awk '{print $1}' "$TMP1" | sort | uniq -d > "$TMP2"
  sort -k 1 "$TMP1" | cut -d' ' -f 1 | uniq -d > "$TMP2"
  while read SUM; do
    grep "^$SUM" "$TMP1" | cut -d' ' -f 2- | sort
    echo
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}

# Remove duplicated files
# Does not handle filenames with \n inside
# Dry-run only, does not execute the rm command
alias rm_dup='rm_duplicates'
rm_duplicates() {
  find_duplicates "$@" | sed '1d ; /^$/{N;d}' | xargs -r -i -- echo "rm -I -- '{}'"
}

# Find duplicate files in directory
find_duplicates0() {
  local TMP1="$(mktemp)"
  local TMP2="$(mktemp)"
  for DIR in "${@:-.}"; do
    find "${DIR:-.}" \( -type f -o -type l \) -exec md5sum -z "{}" \; >> "$TMP1"
  done
  sort -z -k 1 "$TMP1" | cut -z -d' ' -f 1 | uniq -z -d | xargs -0 -n1 > "$TMP2"
  while read SUM; do
    printf "$SUM\0"
    grep -zZ "$SUM" "$TMP1" | sed -z -e "s/$SUM\s*//"
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}

# Remove duplicated files
# Does not handle filenames with \n inside
# Dry-run only, does not execute the rm command
alias rm_dup0='rm_duplicates0'
rm_duplicates0() {
  find_duplicates0 "$@" | xargs -r0 sh -c '
    while [ $# -gt 0 ]; do
      F="$1"; shift
      if [ ! -e "$F" ] && [ ${#F} -eq 32 ]; then
        shift # Skip next file
      elif [ -e "$F" ]; then
        printf "$F\0"
      fi
    done
  ' _ | xargs -r0 -- echo rm -I --
}

# Find duplicate links of all links (good/bad)
ffl_dup() {
  for D in "${@:-.}"; do
    find "$D" -type l -exec sh -c '
	    find "$2" -lname "*$(basename "$(readlink -q "$1")")" -print0 | sort -z | xargs -r0 -- sh -c "[ \$# -ge 1 ] && echo \$0 \$@"
    ' _ {} "$D" \; | sort -u
  done
}
# Find duplicate links (raw list)
ffl_dupr() {
  for D in "${@:-.}"; do
    find "$D" -type l -exec sh -c '
	    find "$2" -lname "*$(basename "$(readlink -q "$1")")" -print0 | sort -z | xargs -r0 -- sh -c "[ \$# -ge 1 ] && echo \$0 && for F; do echo "\$F"; done"
    ' _ {} "$D" \; | sort -u
  done
}

# Find duplicate links of good links
ffl_dupg() {
  for D in "${@:-.}"; do
    find "$D" -type f -exec sh -c '
	    #find -L "$2" -samefile "$1" -xtype l -print0 | xargs -r0 -- echo
      find "$2" -lname "$(basename "$1")" -print0 | xargs -r0 -- echo
    ' _ {} "$D" \;
  done
}
