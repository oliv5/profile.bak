#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
alias ff='_ff'
_ff() {
  local IFS="$(printf '\t\n ')"
  local ARGS="$(shell_ltrim 1 "$@")"
  (set -f; eval _ffind "$(echo "$1" | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g')" "$ARGS")
}

# Various dev search function helpers
h()     { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.h;*.hpp"); }
c()     { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.c;*.cpp;*.cc"); }
hc()    { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp"); }
py()    { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.py"); }
mk()    { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.mk;Makefile"); }
shell() { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.sh"); }
ref()   { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S"); }
v()     { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.vhd;*.v"); }
xml()   { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.xml"); }
asm()   { local ARGS="$(shell_ltrim 2 "$@")"; (set -f; eval NAME= _fgrep "${1}" ${CASE} "$ARGS" "${2:-.}/*.inc;*.S"); }
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
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX_FUNC//\$1/$1}" . -E "$ARGS")
}

var() {
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX_VAR//\$1/$1}" . -E "$ARGS")
}

struct() {
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX_STRUCT//\$1/$1}" . -E "$ARGS")
}

define() {
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX_DEFINE//\$1/$1}" . -E "$ARGS")
}

typedef() {
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX_TYPEDEF//\$1/$1}" . -E "$ARGS")
}

def() {
  local REGEX="($REGEX_FUNC)|($REGEX_VAR)|($REGEX_STRUCT)|($REGEX_DEFINE)|($REGEX_TYPEDEF)"
  local ARGS="$(shell_ltrim 1 "$@")"; (set -f; eval ref "${REGEX//\$1/$1}" . -E "$ARGS")
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
