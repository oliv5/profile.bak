#!/bin/sh
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git*"
GREP_EXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
SED_EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"

# Find files functions
_ffind() {
  local IFS="$(printf '\t\n ')"
  local NAME="${NAME:-name}"
  local ARGS="$(shell_ltrim 1 "$@")"
  local FILES="$(basename "${1:-.}" | sed -e 's/;/ -o -'$NAME' /g')"
  local DIR="$(dirname "${1:-.}")"
  (set -f; eval find -L "$DIR" -nowarn \\\( -$NAME $FILES \\\) -and $FIND_EXCLUDE "$ARGS")
}
ff()  { _ffind "$@" ;}
fff() { local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval _ffind "${1:-*}" -type f "$ARGS"); }
ffd() { local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval _ffind "${1:-*}" -type d "$ARGS"); }
alias iff='NAME=iname ff'
alias ifff='NAME=iname fff'
alias iffd='NAME=iname ffd'

# File grep implementations
_fgrep1() {
  true ${1:?Nothing to do}
  local IFS="$(printf '\t\n ')"
  local ARGS="$(shell_rtrim 1 "$@")"
  local FILES="$(shell_lastargs 1 "$@")"
  (set -f; eval _ffind "$FILES" -type f -print0 | eval xargs -0 grep -nH --color "$ARGS")
}

_fgrep2() {
	local IFS="$(printf '\t\n ')"
	local ARGS="$(shell_rtrim 1 "$@")"
	local FILES="$(shell_lastargs 1 "$@")"
	local DIR="$(dirname "$FILES")"
	local FILES="$(basename "$FILES")"
	(set -f; eval grep -rnH --color "$ARGS" --include="$FILES" "$DIR")
}

# Search pattern functions
gg()  { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval _fgrep2    "\"${1:?Nothing to do}\"" "${2:-*}" "$ARGS"); }
igg() { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval _fgrep2 -i "\"${1:?Nothing to do}\"" "${2:-*}" "$ARGS"); }
ggf() { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval _fgrep2    "\"${1:?Nothing to do}\"" "${2:-*}" "$ARGS" | cut -d : -f 1 | uniq); }
iggf(){ local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval _fgrep2 -i "\"${1:?Nothing to do}\"" "${2:-*}" "$ARGS" | cut -d : -f 1 | uniq); }

# Safe search & replace
_fsed() {
  local SEDOPT="$(shell_rtrim 3 "$@")"
  local IN="$(shell_lastarg 3 "$@" | tr '/' '\/')"
  local OUT="$(shell_lastarg 2 "$@" | tr '/' '\/')"
  local FILES="$(shell_lastarg 1 "$@")"
  echo "Replace '$IN' by '$OUT' in files '$FILES' (opts $SEDOPT) ?"
  local _ANSWER; read -p "Press enter or Ctrl-C" _ANSWER 
  # Sed in place with no output
  #_ffind "$FILES" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #_ffind "$FILES" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  _ffind "$FILES" -type f $SED_EXCLUDE -execdir sed -i _$(date +%Y%m%d-%H%M%S).bak $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed with confirmation about all files
  #_ffind "$FILES" -type f $SED_EXCLUDE -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
hh()  { _fsed "$@" ;}
alias ihh='NAME=iname hh'

