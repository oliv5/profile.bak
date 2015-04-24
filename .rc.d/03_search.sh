#!/bin/sh

# Find files implementations
_ffind1() {
  local FCASE="${FCASE:--}name"
  local DIR="$(dirname "$1 ")" # keep the extra space in $1
  local FILES="$(basename "$1" | sed -e 's/;/ -o '${FCASE}' /g')"
  (set -f; shift $(min 1 $#); find "$DIR" -nowarn ${FTYPE:+-type $FTYPE} \( ${FILES:+$FCASE $FILES} -true \) "$@")
}
_ffind2() {
  local FCASE="${FCASE:--}regex"
  local DIR="$(dirname "$1 ")" # keep the extra space in $1
  local FILES=".*/$(basename "$1")"
  (set -f; shift $(min 1 $#); find "$DIR" -regextype egrep -nowarn ${FTYPE:+-type $FTYPE} ${FILES:+$FCASE $FILES} "$@")
}
alias _ffind='_ffind1'
alias   ff='FCASE=   FTYPE=  _ffind'
alias  fff='FCASE=   FTYPE=f _ffind'
alias  ffd='FCASE=   FTYPE=d _ffind'
alias  ffl='FCASE=   FTYPE=l _ffind'
alias  iff='FCASE=-i FTYPE=  _ffind'
alias ifff='FCASE=-i FTYPE=f _ffind'
alias iffd='FCASE=-i FTYPE=d _ffind'
alias iffl='FCASE=-i FTYPE=l _ffind'

# Backward find
_bfind1() {
  local ABSPATH="$(readlink -f "${1:-$PWD}")"
  local DIR="$(dirname "$ABSPATH")"
  local FILE="$(basename "$ABSPATH")"
  local FIRSTMATCH="$2"
  local FOUND=""
  while true; do
    #if eval test ${BTYPE:--e} "\"$DIR/$FILE\""; then 
    if test ${BTYPE:--e} "$DIR/$FILE"; then 
      FOUND="$DIR"
      [ ! -z "$FIRSTMATCH" ] && break
    fi
    [ -z "$DIR" -o "$DIR" == "." ] && break
    DIR="${DIR%/*}"
  done
  echo "$FOUND"
}
alias _bfind='_bfind1'
alias  bf='BTYPE=   _bfind'
alias bff='BTYPE=-f _bfind'
alias bfd='BTYPE=-d _bfind'

# Find breadth-first (width-first)
_wfind1() { _ffind "${@:-*}" -printf '%d\t%p\n' | sort -nk1 | cut -f2-; }
alias _wfind='_wfind1'
alias  wf='FCASE= FTYPE=  _wfind'
alias wff='FCASE= FTYPE=f _wfind'
alias wfd='FCASE= FTYPE=d _wfind'

# File grep implementations
_fgrep1() {
  command true ${1:?Nothing to do}
  local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
  (set -f; _ffind1 "$@" -type f -print0 | eval xargs -0 grep -nH --color ${GCASE} "$ARGS")
}
_fgrep2() {
	local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
	local DIR="$(dirname "${@:-.}")"
	local FILES="$(basename "$@" | sed -e 's/;/ --include=/g')"
	(set -f; eval grep -RnH --color ${GCASE} "$ARGS" --include="$FILES" "$DIR")
}
alias _fgrep='_fgrep2'
alias   gg='GCASE=   _fgrep'
alias  igg='GCASE=-i _fgrep'
ggl() {  gg "$@" | cut -d : -f 1 | uniq; }
iggl(){ igg "$@" | cut -d : -f 1 | uniq; }

# Safe search & replace
_fsed1() {
  local SEDOPT="$(shell_rtrim 3 "$@")"; shift $(($#-3))
  local IN="$1"; local OUT="$2"; local FILES="$3"
  # Last chance to exit
  echo "Replace '$IN' by '$OUT' in files '$FILES' (opts $SEDOPT) ?"
  local _ANSWER; read -p "Press enter or Ctrl-C" _ANSWER 
  # Sed in place with no output
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  eval _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i _$(date +%Y%m%d-%H%M%S).bak $SEDOPT "\"s/$IN/$OUT/g\"" "{} \;"
  # Sed with confirmation about all files
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
alias _fsed='_fsed1'
alias  hh='FCASE=   SEXCLUDE= _fsed'
alias ihh='FCASE=-i SEXCLUDE= _fsed'
