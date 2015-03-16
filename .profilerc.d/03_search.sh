#!/bin/sh
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git*"
GREP_EXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
SED_EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"

# Find files functions
_ffind() {
  local NAME="${NAME:-name}"
  local FILES="$(basename "${1:-.}" | sed -e 's/;/ -o -'$NAME' /g')"
  local DIR="$(dirname "${1:-.}")"
  (set -f; shift; find -L "$DIR" -nowarn \( -$NAME $FILES \) -and $FIND_EXCLUDE "$@")
}
ff()  { (set -f; _ffind "$@"); }
fff() { local ARG1="$1"; shift; (set -f; _ffind "${ARG1:-*}" -type f "$@"); }
ffd() { local ARG1="$1"; shift; (set -f; _ffind "${ARG1:-*}" -type d "$@"); }
alias iff='NAME=iname ff'
alias ifff='NAME=iname fff'
alias iffd='NAME=iname ffd'

# File grep implementations
alias _fgrep='_fgrep2'
_fgrep1() {
  true ${1:?Nothing to do}
  local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
  (set -f; _ffind "$@" -type f -print0 | eval xargs -0 grep -nH --color "$ARGS")
}

_fgrep2() {
	local ARGS="$(shell_rtrim 1 "$@")"
  shift $(($#-1))
	local FILES="$@"
	local DIR="$(dirname "$FILES")"
	local FILES="$(basename "$FILES")"
	(set -f; eval grep -rnH --color "$ARGS" --include="$FILES" "$DIR")
}

# Search pattern functions
gg()  { local ARG1="$1"; local ARG2="$2"; shift 2; (set -f; _fgrep2    "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@"); }
igg() { local ARG1="$1"; local ARG2="$2"; shift 2; (set -f; _fgrep2 -i "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@"); }
ggf() { local ARG1="$1"; local ARG2="$2"; shift 2; (set -f; _fgrep2    "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@" | cut -d : -f 1 | uniq); }
iggf(){ local ARG1="$1"; local ARG2="$2"; shift 2; (set -f; _fgrep2 -i "${ARG1:?Nothing to do}" "${ARG2:-*}" "$@" | cut -d : -f 1 | uniq); }

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
alias ihh='NAME=iname hh'

