#!/bin/sh

# Find files implementations
_ffind1() {
  local FCASE="${FCASE:--}name"
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  FILES="$(echo "$FILES" | sed -e 's/;/ -o '${FCASE}' /g')"
  (set -f; shift $(min 1 $#); find "${DIR:-.}" -nowarn ${FTYPE:+-type $FTYPE} ${FXTYPE:+-xtype $FXTYPE} \( ${FILES:+$FCASE $FILES} -true \) "$@")
}
_ffind2() {
  local FCASE="${FCASE:--}regex"
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  (set -f; shift $(min 1 $#); find "${DIR:-.}" -regextype egrep -nowarn ${FTYPE:+-type $FTYPE} ${FXTYPE:+-xtype $FXTYPE} ${FILES:+$FCASE .*/$FILES} "$@")
}
alias _ffind='_ffind1'
alias    ff='FCASE=   FTYPE=  FXTYPE=  _ffind'
alias   fff='FCASE=   FTYPE=f FXTYPE=  _ffind'
alias   ffd='FCASE=   FTYPE=d FXTYPE=  _ffind'
alias   ffl='FCASE=   FTYPE=l FXTYPE=  _ffind'
alias  ffll='FCASE=   FTYPE=l FXTYPE=f _ffind'
alias  fflb='FCASE=   FTYPE=l FXTYPE=l _ffind'
alias   iff='FCASE=-i FTYPE=  FXTYPE=  _ffind'
alias  ifff='FCASE=-i FTYPE=f FXTYPE=  _ffind'
alias  iffd='FCASE=-i FTYPE=d FXTYPE=  _ffind'
alias  iffl='FCASE=-i FTYPE=l FXTYPE=  _ffind'
alias iffll='FCASE=-i FTYPE=l FXTYPE=f _ffind'
alias ifflb='FCASE=-i FTYPE=l FXTYPE=l _ffind'

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
alias  bf='BTYPE=   _bfind'
alias bff='BTYPE=-f _bfind'
alias bfd='BTYPE=-d _bfind'

# Find breadth-first (width-first)
_wfind1() { _ffind "${@:-*}" -prune -printf '%d\t%p\n' | sort -nk1 | cut -f2-; }
alias _wfind='_wfind1'
alias   wf='FCASE= FTYPE=  FXTYPE=  _wfind'
alias  wff='FCASE= FTYPE=f FXTYPE=  _wfind'
alias  wfd='FCASE= FTYPE=d FXTYPE=  _wfind'
alias  wfl='FCASE= FTYPE=l FXTYPE=  _wfind'
alias wfll='FCASE= FTYPE=l FXTYPE=f _wfind'
alias wflb='FCASE= FTYPE=l FXTYPE=l _wfind'

# File grep implementations
_fgrep1() {
  command true ${1:?Nothing to do}
  local ARGS="$(arg_rtrim 1 "$@")"
  shift $(($#-1))
  (set -f; _ffind1 "$@" -type f -print0 | eval xargs -0 grep -nH --color ${GCASE} "$ARGS")
}
_fgrep2() {
  local ARGS="$(arg_rtrim 1 "$@")"
  shift $(($#-1))
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  FILES="$(echo "${FILES}" | sed -e 's/;/ --include=/g')"
  (set -f; eval grep -RnH --color ${GCASE} "$ARGS" --include="$FILES" "${DIR:-.}")
}
alias _fgrep='_fgrep2'
alias   gg='GCASE=   _fgrep'
alias  igg='GCASE=-i _fgrep'
ggl() {  gg "$@" | cut -d : -f 1 | uniq; }
iggl(){ igg "$@" | cut -d : -f 1 | uniq; }

# Safe search & replace
_fsed1() {
  local SEDOPT="$(arg_rtrim 3 "$@")"; shift $(($#-3))
  local IN="$1"; local OUT="$2"; local FILES="$3"
  # Last chance to exit
  echo "Replace '$IN' by '$OUT' in files '$FILES' (opts $SEDOPT) ?"
  local _ANSWER; read -p "Press enter or Ctrl-C" _ANSWER 
  # Sed in place with no output
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  eval FTYPE= FXTYPE= _ffind "\"$FILES\"" $SEXCLUDE -type f -execdir sed -i _$(date +%Y%m%d-%H%M%S).bak $SEDOPT "\"s/$IN/$OUT/g\"" "{} \;"
  # Sed with confirmation about all files
  #eval _ffind "\"$FILES\"" $SEXCLUDE -type f -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
alias _fsed='_fsed1'
alias  hh='FCASE=   SEXCLUDE= _fsed'
alias ihh='FCASE=-i SEXCLUDE= _fsed'
