#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
alias ff='_ff'
_ff() {
  local ARG1="$1"; shift $(min 1 $#)
  (set -f; _ffind "$(echo "${ARG1:-*}" | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g')" "$@")
}

# Various dev search function helpers
h()     { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.h;*.hpp"); }
c()     { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.c;*.cpp;*.cc"); }
hc()    { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp"); }
py()    { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.py"); }
mk()    { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.mk;Makefile"); }
shell() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.sh"); }
ref()   { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S"); }
v()     { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.vhd;*.v"); }
xml()   { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.xml"); }
asm()   { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; NAME= _fgrep "$ARG1" ${CASE} "$@" "${ARG2:-.}/*.inc;*.S"); }
alias ih='CASE=-i h'
alias ic='CASE=-i c'
alias ihc='CASE=-i hc'
alias ipy='CASE=-i py'
alias imk='CASE=-i mk'
alias ishell='CASE=-i shell'
alias iref='CASE=-i ref'
alias iv='CASE=-i v'
alias ixml='CASE=-i xml'
alias iasm='CASE=-i asm'

# Search regex
#REGEX_FUNC='(^|\s+|::)$1\s*\(([^;]*$|[^\}]\})'
REGEX_FUNC='\w+\s+$1\s*\(\s*($|\w+\s+\w+|void)'
REGEX_VAR='^[^\(]*\w+\s*(\*|&)*\s*$1\s*(=.+|\(\w+\)|\[.+\])?\s*(;|,)'
REGEX_STRUCT='(struct|union|enum|class)\s*$1\s*(\{|$)'
REGEX_TYPEDEF='(typedef\s+\w+\s$1)|(^\s*$1\s*;)'
REGEX_DEFINE='(#define\s+$1|^\s*$1\s*,)|(^\s*$1\s*=.*,)'

func() {
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX_FUNC//\$ARG1/$ARG1}" . -E "$@")
}

var() {
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX_VAR//\$ARG1/$ARG1}" . -E "$@")
}

struct() {
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX_STRUCT//\$ARG1/$ARG1}" . -E "$@")
}

define() {
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX_DEFINE//\$ARG1/$ARG1}" . -E "$@")
}

typedef() {
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX_TYPEDEF//\$ARG1/$ARG1}" . -E "$@")
}

def() {
  local REGEX="($REGEX_FUNC)|($REGEX_VAR)|($REGEX_STRUCT)|($REGEX_DEFINE)|($REGEX_TYPEDEF)"
  local ARG1="$1"; shift $(min 1 $#); (set -f; ref "${REGEX//\$ARG1/$ARG1}" . -E "$@")
}

# Search alias
alias class='struct'
alias union='struct'
alias enum='struct'
alias ifunc='CASE=-i func'
alias ivar='CASE=-i var'
alias istruct='CASE=-i struct'
alias ienum='CASE=-i enum'
alias iunion='CASE=-i union'
alias iclass='CASE=-i class'
alias itypedef='CASE=-i typedef'
alias idef='CASE=-i def'

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}
