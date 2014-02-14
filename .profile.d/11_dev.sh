#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
unalias ff  2>/dev/null
function ff() {
  _find "$(sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g' <<< $1)" "${@:2}"
}

# Various dev search function helpers
#### DIR=.;OPT=; [ $# -gt 1 ] && DIR=${!#} && OPT=${@:2:($#-2)}; echo _fgrep "${1}" ${CASE} $OPT "${DIR}/*.h|*.hpp";
function h()     { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.h|*.hpp"; }
function c()     { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc"; }
function hc()    { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp"; }
function py()    { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.py"; }
function mk()    { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.mk|Makefile"; }
function shell() { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.sh"; }
function ref()   { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp|*.py|*.mk|Makefile|*.sh|*.vhd|*.v|*.inc|*.S"; }
function v()     { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.vhd|*.v"; }
function xml()   { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.xml"; }
function asm()   { _fgrep "${1}" ${CASE} "${@:3}" "${2:-.}/*.inc|*.S"; }
alias ih='CASE=-i h'
alias ic='CASE=-i c'
alias ihc='CASE=-i hc'
alias ipy='CASE=-i py'
alias imk='CASE=-i mk'
alias ishell='CASE=-i shell'
alias iref='CASE=-i ref'
alias iv='CASE=-i v'
alias iasm='CASE=-i asm'

# Prototype search helper
function proto() {
  # Function/variable definition regex
  ref "(void|int|bool|char|float|double|u8|u16|u32|s8|s16|s32) *\*? *$1 *(.*) *;"
}

# Definition search helper
alias idef='CASE=-i def'
function def
{
  # Function/variable definition regex
  typeset pattern="((void|int|bool|char|float|double|u8|u16|u32|s8|s16|s32) *\*? *(const)? *$1)"
  # Structure definition regex
  pattern="$pattern|(^ *struct *$1)"
  # 1-line type definition regex
  pattern="$pattern|(typedef.*$1 *;)"
  # Constant definition
  pattern="$pattern|(#define *$1(\([^\)]*\))?)"
  # Now search
  ref "$pattern"
}

# Hexdump to txt 32 bits
function bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}
