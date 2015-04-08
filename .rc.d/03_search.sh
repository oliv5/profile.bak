#!/bin/sh
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git*"
GREP_EXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
SED_EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"

# Find files implementations
alias _ffind='_ffind1'
_ffind1() {
  local FCASE="${FCASE:--}name"
  local DIR="$(dirname "$1")"
  local FILES="$FCASE $(basename "$1" | sed -e 's/;/ -o '${FCASE}' /g')"
  (set -f; shift $(min 1 $#); find -L "$DIR" -nowarn \( $FILES \) -and $FIND_EXCLUDE "$@")
}
_ffind2() {
  local FCASE="${FCASE:--}regex"
  local DIR="$(dirname "$1")"
  local FILES="$FCASE .*/$(basename "$1")"
  (set -f; shift $(min 1 $#); find -L "$DIR" -regextype egrep -nowarn $FILES -and $FIND_EXCLUDE "$@")
}
fff() { local ARG1="$1"; shift $(min 1 $#); (set -f; _ffind "${ARG1:-*}" -type f "$@"); }
ffd() { local ARG1="$1"; shift $(min 1 $#); (set -f; _ffind "${ARG1:-*}" -type d "$@"); }
alias ff='_ffind'
alias iff='FCASE=-i ff'
alias ifff='FCASE=-i fff'
alias iffd='FCASE=-i ffd'

# Backward find
_bfind() {
  local DIR="$(dirname "$1")"
  local NAME="$(basename "$1")"
  local TYPE="${2:-e}"
  local STOP="$3"
  local FOUND=""
  while true; do
    if eval test -$TYPE "\"$DIR/$NAME\""; then 
      FOUND="$DIR"
      [ -z "$STOP" ] && break
    fi
    [ -z "$DIR" -o "$DIR" == "." ] && break
    DIR="${DIR%/*}"
  done
  echo "$FOUND"
}
bff() { local ARG1="$1"; shift $(min 1 $#); (set -f; _bfind "${ARG1:-.}" "f" "$@"); }
bfd() { local ARG1="$1"; shift $(min 1 $#); (set -f; _bfind "${ARG1:-.}" "d" "$@"); }
alias bf='_bfind'

# Find breadth-first (width-first)
_wfind() { _ffind "${@:-*}" -printf '%d\t%p\n' | sort -nk1 | cut -f2-; }
wff() { _wfind "${@:-*}" -type f; }
wfd() { _wfind "${@:-*}" -type d; }
alias wf='_wfind'

# File grep implementations
alias _fgrep='_fgrep2'
_fgrep1() {
  command true ${1:?Nothing to do}
  local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
  (set -f; _ffind1 "$@" -type f -print0 | eval xargs -0 grep -nH --color "$ARGS")
}
_fgrep2() {
	local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
	local DIR="$(dirname "${@:-.}")"
	local FILES="$(basename "$@" | sed -e 's/;/ --include=/g')"
	(set -f; eval grep -RnH --color "$ARGS" --include="$FILES" "$DIR")
}

# Search pattern functions
gg()  { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _fgrep    "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@"); }
igg() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _fgrep -i "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@"); }
ggf() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _fgrep    "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@" | cut -d : -f 1 | uniq); }
iggf(){ local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _fgrep -i "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@" | cut -d : -f 1 | uniq); }

# Safe search & replace
_fsed() {
  local SEDOPT="$(shell_rtrim 3 "$@")"; shift $(($#-3))
  local IN="$1"; local OUT="$2"; local FILES="$3"
  # Last chance to exit
  echo "Replace '$IN' by '$OUT' in files '$FILES' (opts $SEDOPT) ?"
  local _ANSWER; read -p "Press enter or Ctrl-C" _ANSWER 
  # Sed in place with no output
  #_ffind "$FILES" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #_ffind "$FILES" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  eval _ffind "\"$FILES\"" -type f $SED_EXCLUDE -execdir sed -i _$(date +%Y%m%d-%H%M%S).bak $SEDOPT "\"s/$IN/$OUT/g\"" "{} \;"
  # Sed with confirmation about all files
  #_ffind "$FILES" -type f $SED_EXCLUDE -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
hh()  { _fsed "$@" ;}
alias ihh='FCASE=-i hh'
