#!/bin/sh

###########################################
# Find files implementations
_ffind3() {
  local FCASE="${FCASE:--}name"
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  ${1:-true} || shift
  local REGEX='s/;!/" -o -not '${FCASE}' "/g ; s/&!/" -a -not '${FCASE}' "/g ; s/;/" -o '${FCASE}' "/g ; s/&/" -a '${FCASE}' /g'
  ( set -f; FILES="\"$(echo ${FILES:-*} | sed -e "$REGEX")\""
    eval find "${DIR:-.}" ${FTYPE:+-type $FTYPE} ${FILES:+$FCASE "$FILES"} ${FARGS} "$@")
}
alias _ffind='_ffind3'

###########################################
# File grep implementations
# Replace "grep -R" by "grep -r"
_fgrep2() {
  if [ $# -gt 1 ]; then
    local ARGS="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  else
    local ARGS="$1"; shift $#
  fi
  local FILES="${1##*/}"
  local DIR="${1%"$FILES"}"
  FILES="$(echo "${FILES}" | sed -e 's/;/ --include=/g')"
  (set -f; eval grep -rnH --color ${GCASE} ${GARGS} -e "$ARGS" ${FILES:+--include="$FILES"} "${DIR:-.}")
}
