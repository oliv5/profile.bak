#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
alias ff='_ff'
_ff() {
  _ffind "$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g' <<< $1)" "${@:2}"
}

# Various dev search function helpers
#### DIR=.;OPT=; [ $# -gt 1 ] && DIR=${!#} && OPT=${@:2:($#-2)}; echo _fgrep "${1}" ${CASE} $OPT "${DIR}/*.h;*.hpp";
h()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.h;*.hpp"; }
c()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c;*.cpp;*.cc"; }
hc()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp"; }
py()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.py"; }
mk()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.mk;Makefile"; }
shell() { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.sh"; }
ref()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S"; }
v()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.vhd;*.v"; }
xml()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.xml"; }
asm()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.inc;*.S"; }
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
#REGEX_VAR='(^|;)\s*\w+\s+$1\s*(=.+)?;'
#REGEX_VAR='\w+\s+$1\s*(=.+|\(\w+\))?\s*;'
REGEX_VAR='\w+\s*\**\s*$1\s*(=.+|\(\w+\)|\[.+\])?\s*;'
REGEX_STRUCT='(struct|union|enum|class)\s*$1\s*(\{|$)'
REGEX_TYPEDEF='(typedef\s+\w+\s$1)|(^\s*$1\s*;)'
REGEX_DEFINE='(#define\s+$1|^\s*$1\s*,)|(^\s*$1\s*=.*,)'

func() {
  ref "${REGEX_FUNC//\$1/$1}" . -E ${@:2}
}

var() {
  ref "${REGEX_VAR//\$1/$1}" . -E ${@:2}
}

struct() {
  ref "${REGEX_STRUCT//\$1/$1}" . -E ${@:2}
}

define() {
  ref "${REGEX_DEFINE//\$1/$1}" . -E ${@:2}
}

typedef() {
  ref "${REGEX_TYPEDEF//\$1/$1}" . -E ${@:2}
}

def() {
  REGEX="($REGEX_FUNC)|($REGEX_VAR)|($REGEX_STRUCT)|($REGEX_DEFINE)|($REGEX_TYPEDEF)"
  ref "${REGEX//\$1/$1}" . -E ${@:2}
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
