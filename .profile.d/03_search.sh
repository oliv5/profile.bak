#!/bin/bash
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git"

# Find files functions
function _find() {
  trap "set +f; trap SIGINT" SIGINT
  set -f
  find "$(dirname ${1:-.})" \( -${NAME:-name} $(sed -e 's/|/ -o -'${NAME:-name}' /g' <<< $(basename ${1:-*})) \) -and $FIND_EXCLUDE "${@:2}"
  set +f
  trap SIGINT
}
function ff() { _find "$@" -type f ;}
function fd() { _find "$@" -type d ;}
alias f='_find'
alias iff='NAME=iname ff'
alias ifd='NAME=iname fd'

# Search pattern functions
function _fgrep() {
  NAME=${NAME:-name} _find "${!#}" -type f -print0 | xargs -0 grep -E -n --color "${@:1:$(($#-1))}"
}
alias gg='_fgrep'
alias ig='NAME=iname gg'

# Safe search & replace
function _fsed()
{
  EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"
  SEDOPT="${@:1:$(($#-3))}"
  IN="${@: -3:1}"; IN="${IN//\//\/}"
  OUT="${@: -2:1}"
  echo "Replace '$IN' by '$OUT' in files '${!#}' from directory '$DIR'?"
  echo "Press enter or Ctrl-C" ; read
  NAME=${NAME:-name} _find "${!#}" -type f $EXCLUDE -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
alias hh='_fsed'
alias ih='NAME=iname hh'
