#!/bin/sh

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


