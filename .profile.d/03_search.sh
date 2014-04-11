#!/bin/bash
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git"

# Find files functions
function _find() {
  trap "set +f; trap SIGINT" SIGINT
  set -f
  find -L "$(dirname ${1:-.})" \( -${NAME:-name} $(sed -e 's/;/ -o -'${NAME:-name}' /g' <<< $(basename ${1:-*})) \) -and $FIND_EXCLUDE "${@:2}"
  set +f
  trap SIGINT
}
function ff() { _find "$@" ;}
function fff() { _find "${@:-*}" -type f ;}
function ffd() { _find "${@:-*}" -type d ;}
alias iff='NAME=iname ff'
alias ifff='NAME=iname fff'
alias iffd='NAME=iname ffd'

# Search pattern functions
function _fgrep() {
  [ "$1" != "" ] && NAME=${NAME:-name} _find "${!#}" -type f -print0 | xargs -0 grep -n --color "${@:1:($#-1)}"
}
alias gg='NAME=name _fgrep'
alias igg='NAME=iname gg'

# Safe search & replace
function _fsed()
{
  EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"
  SEDOPT="${@:1:$(($#-3))}"
  IN="${@: -3:1}"; IN="${IN//\//\/}"
  OUT="${@: -2:1}";  OUT="${OUT//\//\/}"
  echo "Replace '$IN' by '$OUT' in files '${!#}'?"
  echo "Press enter or Ctrl-C" ; read
  # Sed in place with no output
  #NAME=${NAME:-name} _find "${!#}" -type f $EXCLUDE -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #NAME=${NAME:-name} _find "${!#}" -type f $EXCLUDE -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  NAME=${NAME:-name} _find "${!#}" -type f $EXCLUDE -execdir sed -i_$(date +%Y%m%d-%H%M%S).bak $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed with confirmation about all files
  #NAME=${NAME:-name} _find "${!#}" -type f $EXCLUDE -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
alias hh='NAME=name _fsed'
alias ihh='NAME=iname hh'
