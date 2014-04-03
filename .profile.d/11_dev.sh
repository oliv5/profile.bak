#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
alias ff='NAME=name _ff'
function _ff() {
  _find "$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g' <<< $1)" "${@:2}"
}

# Various dev search function helpers
#### DIR=.;OPT=; [ $# -gt 1 ] && DIR=${!#} && OPT=${@:2:($#-2)}; echo _fgrep "${1}" ${CASE} $OPT "${DIR}/*.h|*.hpp";
function h()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.h|*.hpp"; }
function c()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc"; }
function hc()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp"; }
function py()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.py"; }
function mk()    { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.mk|Makefile"; }
function shell() { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.sh"; }
function ref()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp|*.py|*.mk|Makefile|*.sh|*.vhd|*.v|*.inc|*.S"; }
function v()     { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.vhd|*.v"; }
function xml()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.xml"; }
function asm()   { NAME= _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.inc|*.S"; }
alias ih='CASE=-i h'
alias ic='CASE=-i c'
alias ihc='CASE=-i hc'
alias ipy='CASE=-i py'
alias imk='CASE=-i mk'
alias ishell='CASE=-i shell'
alias iref='CASE=-i ref'
alias iv='CASE=-i v'
alias iasm='CASE=-i asm'

# Search regex
REGEX_FUNC='(^|[ \t]+|::)$1[ \t]*\(([^;]*$|[^\}]\})'
#REGEX_VAR='(^|;)[ \t]*\w+[ \t]+$1[ \t]*(=.+)?;'
REGEX_VAR='[ \t]*\w+[ \t]+$1[ \t]*(=.+)?;'
REGEX_STRUCT='(struct|union|enum|class)[ \t]*$1[ \t]*(\{|\$)'
REGEX_TYPEDEF='(typedef[ \t]\w+[ \t]$1)|(^[ \t]*$1[ \t]*;)'
REGEX_DEFINE='(#define[ \t]+$1|^[ \t]*$1[ \t]*,)|(^[ \t]*$1[ \t]*=.*,)'

function func() {
  ref "${REGEX_FUNC//\$1/$1}" . -E ${@:2}
}

function var() {
  ref "${REGEX_VAR//\$1/$1}" . -E ${@:2}
}

function struct() {
  ref "${REGEX_STRUCT//\$1/$1}" . -E ${@:2}
}

function define() {
  ref "${REGEX_DEFINE//\$1/$1}" . -E ${@:2}
}

function typedef() {
  ref "${REGEX_TYPEDEF//\$1/$1}" . -E ${@:2}
}

function def() {
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
function bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}
