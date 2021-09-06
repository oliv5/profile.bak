#!/bin/sh
if command -v rg >/dev/null; then
alias rgrep='rg --no-heading -n'
alias rg='rg --no-heading -n'

###########################################
_rgrep() {
  local PATTERN="$1"
  local FILES="${2##*/}"
  local DIR="${2%"$FILES"}"
  FILES="$(echo "${FILES}" | sed -e 's/;/|/g')"
  shift 2
  command rg --no-heading -n ${GARGS} -g "${FILES}" "$@" "${PATTERN}" "${DIR:-.}"
}
unset GARGS
alias    gg='GARGS="" _rgrep'
alias   igg='GARGS="-i" _rgrep'
alias   ggl='GARGS="-L" _rgrep'
alias  iggl='GARGS="-i -L" _rgrep'
alias   ggs='gg   2>/dev/null'
alias  iggs='igg  2>/dev/null'
alias  ggls='ggl  2>/dev/null'
alias iggls='iggl 2>/dev/null'

###########################################
fi
