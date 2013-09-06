#!/bin/bash
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git"
GREP_EXCLUDE="\.git\|\.svn"

# Find files functions
alias ff='_ff'
alias iff='NAME=iname _ff'
function _ff() {
  set -f
  NAME=${NAME:-name} find "$(dirname ${1:-.})" \( -$NAME $(sed -e 's/|/ -o -'$NAME' /g' <<< $(basename ${1:-*})) \) -and $FIND_EXCLUDE "${@:2}"
  set +f
}

# Search pattern functions
alias gg='_gg'
alias igg='NAME=iname _gg'
function _gg() {
  set -f
  NAME=${NAME:-name} _ff "${!#}" -type f | xargs grep -E -n --color "${@:1:$(($#-1))}"
  set +f
}

# Safe search & replace
alias hh='_hh'
alias ihh='NAME=iname _hh'
function _hh()
{
  set -f
  EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"
  SEDOPT="${@:1:$(($#-3))}"
  IN="${@: -3:1}"; IN="${IN//\//\/}"
  OUT="${@: -2:1}"
  echo "Replace '$IN' by '$OUT' in files '${!#}' from directory '$DIR'?"
  echo "Press enter or Ctrl-C" ; read
  NAME=${NAME:-name} _ff "${!#}" -type f $EXCLUDE -execdir sed $SEDOPT "s/$IN/$OUT/g" {} \;
  set +f
}

# Find and open files functions
alias ffo='ffv'
function ffv() {
  ff "$@" -execdir sh -c '${VISUAL} "$0"' "{}" \;
}

# diff directories
function diffd() {
  diff -qr "$@" | grep -v -e $GREP_EXCLUDE
}
