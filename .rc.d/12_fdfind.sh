#!/bin/sh
if command -v fdfind >/dev/null; then
alias fd='fdfind'

###########################################
# double underscore: _fdfind is defined by fdfind already...
__fdfind() {
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  FILES="$(_fregex "${FILES}")"
  shift
  fdfind ${FTYPE:+-t $FTYPE} ${FCASE} ${FARGS} --no-ignore --hidden "${FILES:-.*}" "$@" "${DIR:-.}"
}

#~ _fdfind_test() {
  #~ cd $(mktemp -d)
  #~ mkdir -p a/b/c
  #~ touch a/b/c/toto.txt a/b/c/toto.txt2
  #~ echo "Test"; _fdfind "toto.txt"
  #~ echo "Test"; _fdfind "./toto.txt"
  #~ echo "Test"; _fdfind "./a*/toto.txt"
  #~ echo "Test"; _fdfind "./a*/*b/toto.txt"
  #~ echo "Test"; _fdfind "toto.*"
  #~ echo "Test"; _fdfind "./toto.*"
  #~ echo "Test"; _fdfind "./a*/toto.*"
  #~ echo "Test"; _fdfind "./a*/*b/toto.*"
  #~ echo "Test"; _fdfind "/etc"
  #~ rm a/b/c/toto.txt a/b/c/toto.txt2
  #~ rmdir -p a/b/c
#~ }

##########
unset FCASE FTYPE FARGS
alias      ff='FCASE=   FTYPE=  FARGS="${FARGS}" __fdfind'
alias     fff='FCASE=   FTYPE=f FARGS="${FARGS}" __fdfind'
alias     ffd='FCASE=   FTYPE=d FARGS="${FARGS}" __fdfind'
alias     ffl='FCASE=   FTYPE=l FARGS="${FARGS}" __fdfind'
alias     iff='FCASE=-i FTYPE=  FARGS="${FARGS}" __fdfind'
alias    ifff='FCASE=-i FTYPE=f FARGS="${FARGS}" __fdfind'
alias    iffd='FCASE=-i FTYPE=d FARGS="${FARGS}" __fdfind'
alias    iffl='FCASE=-i FTYPE=l FARGS="${FARGS}" __fdfind'
alias     ff0='FARGS=-0 ff'
alias    fff0='FARGS=-0 fff'
alias    ffd0='FARGS=-0 ffd'
alias    ffl0='FARGS=-0 ffl'
alias    iff0='FARGS=-0 iff'
alias   ifff0='FARGS=-0 ifff'
alias   iffd0='FARGS=-0 iffd'
alias   iffl0='FARGS=-0 iffl'
alias     ffs='ff    2>/dev/null'
alias    fffs='fff   2>/dev/null'
alias    ffds='ffd   2>/dev/null'
alias    ffls='ffl   2>/dev/null'
alias    iffs='iff   2>/dev/null'
alias   ifffs='ifff  2>/dev/null'
alias   iffds='iffd  2>/dev/null'
alias   iffls='iffl  2>/dev/null'
alias    ff1='FARGS=-maxdepth 1 ff'
alias   fff1='FARGS=-maxdepth 1 fff'
alias   ffd1='FARGS=-maxdepth 1 ffd'
alias   ffl1='FARGS=-maxdepth 1 ffl'
alias   iff1='FARGS=-maxdepth 1 iff'
alias  ifff1='FARGS=-maxdepth 1 ifff'
alias  iffd1='FARGS=-maxdepth 1 iffd'
alias  iffl1='FARGS=-maxdepth 1 iffl'
alias    ff2='FARGS=-maxdepth 2 ff'
alias   fff2='FARGS=-maxdepth 2 fff'
alias   ffd2='FARGS=-maxdepth 2 ffd'
alias   ffl2='FARGS=-maxdepth 2 ffl'
alias   iff2='FARGS=-maxdepth 2 iff'
alias  ifff2='FARGS=-maxdepth 2 ifff'
alias  iffd2='FARGS=-maxdepth 2 iffd'
alias  iffl2='FARGS=-maxdepth 2 iffl'

###########################################
# File grep implementations
_fdgrep1() {
  if [ $# -gt 1 ]; then
    local ARGS="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  else
    local ARGS="$1"; shift $#
  fi
  (set -f; __fdfind "$@" -t f -0 |
    eval xargs -r0 grep -nH --color ${GCASE} ${GARGS} -e "${ARGS:-''}")
}
_fdgrep() { _fdgrep1 "$@"; }
unset GCASE GARGS
alias    gg='FCASE= FTYPE= FXTYPE= FOPTS=-L FARGS= GCASE=   GARGS=   _fdgrep'
alias   igg='FCASE= FTYPE= FXTYPE= FOPTS=-L FARGS= GCASE=-i GARGS=   _fdgrep'
alias   ggl='FCASE= FTYPE= FXTYPE= FOPTS=   FARGS= GCASE=   GARGS=-l _fdgrep'
alias  iggl='FCASE= FTYPE= FXTYPE= FOPTS=   FARGS= GCASE=-i GARGS=-l _fdgrep'
alias   ggs='gg   2>/dev/null'
alias  iggs='igg  2>/dev/null'
alias  ggls='ggl  2>/dev/null'
alias iggls='iggl 2>/dev/null'

###########################################
# Search & replace
_fdsed1() {
  local SEDOPT=""; [ $# -gt 3 ] && SEDOPT="$1" && shift 1
  local IN="$1"; local OUT="$2"; local FILES="${SFILES:-$3}"
  ${SNOCONFIRM:+true} echo "Replace '$IN' by '$OUT' in files '$FILES' ${SEDOPT:+with options $SEDOPT}"
  ${SNOCONFIRM:+true} read -p "Confirm ? (enter/ctrl-c) " _
  # Call find and sed
  __fdfind "$FILES" ${SEXCLUDE} -t f -0 |
    xargs -r0 sed ${SEDOPT} --in-place -e "s|$IN|$OUT|g"
}
unset SFILES SEXCLUDE SNOCONFIRM
_fdsed() { _fdsed1 "$@"; }
alias   hh='FCASE=   FTYPE= FXTYPE= FOPTS= FARGS= SFILES= SEXCLUDE= _fdsed'
alias  ihh='FCASE=-i FTYPE= FXTYPE= FOPTS= FARGS= SFILES= SEXCLUDE= _fdsed'

###########################################
fi
