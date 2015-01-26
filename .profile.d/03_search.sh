#!/bin/sh
FIND_EXCLUDE="-not -path *.svn* -and -not -path *.git*"
GREP_EXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
SED_EXCLUDE="$FIND_EXCLUDE -not -type l -and -not -path '*obj*'"

# Find files functions
_ffind() {
  trap "set +f; trap SIGINT" SIGINT
  set -f
  find -L "$(dirname "${1:-.}")" -nowarn \( -${NAME:-name} $(sed -e 's/;/ -o -'${NAME:-name}' /g' <<< $(basename "${1:-*}")) \) -and $FIND_EXCLUDE "${@:2}"
  set +f
  trap SIGINT
}
ff()  { _ffind "$@" ;}
fff() { _ffind "${1:-*}" -type f "${@:2}" ;}
ffd() { _ffind "${1:-*}" -type d "${@:2}" ;}
alias iff='NAME=iname ff'
alias ifff='NAME=iname fff'
alias iffd='NAME=iname ffd'

# Search pattern functions
_fgrep() {
  [ $# -ge 1 ] && _ffind "${!#}" -type f -print0 | xargs -0 $(which grep) -nH --color "${@:1:($#-1)}"
}
_fgrep2() {
  $(which grep) --color=auto -rnH $GREP_EXCLUDE "${@:1:$(($# - 1))}" --include=${!#}
}
gg()  { _fgrep2    "${1:?Nothing to do}" "${2:-*}" "${@:3}" ;}
igg() { _fgrep2 -i "${1:?Nothing to do}" "${2:-*}" "${@:3}" ;}
ggf() { _fgrep2    "${1:?Nothing to do}" "${2:-*}" "${@:3}" | cut -d : -f 1 | uniq ;}
iggf(){ _fgrep2 -i "${1:?Nothing to do}" "${2:-*}" "${@:3}" | cut -d : -f 1 | uniq ;}

# Safe search & replace
_fsed() {
  SEDOPT="${@:1:$(($#-3))}"
  IN="${@: -3:1}"; IN="${IN//\//\/}"
  OUT="${@: -2:1}";  OUT="${OUT//\//\/}"
  echo "Replace '$IN' by '$OUT' in files '${!#}' (opts $SEDOPT) ?"
  echo "Press enter or Ctrl-C" ; read
  # Sed in place with no output
  #_ffind "${!#}" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed in place with display
  #_ffind "${!#}" -type f $SED_EXCLUDE -execdir sed -i $SEDOPT -e "/$IN/{w /dev/stderr" -e "}" -e "s/$IN/$OUT/g" {} \;
  # Sed in place with backup
  _ffind "${!#}" -type f $SED_EXCLUDE -execdir sed -i _$(date +%Y%m%d-%H%M%S).bak $SEDOPT "s/$IN/$OUT/g" {} \;
  # Sed with confirmation about all files
  #_ffind "${!#}" -type f $SED_EXCLUDE -exec echo "Processing file {} ?" \; -exec bash -c read \; -execdir sed -i $SEDOPT "s/$IN/$OUT/g" {} \;
}
hh()  { _fsed "$@" ;}
alias ihh='NAME=iname hh'

