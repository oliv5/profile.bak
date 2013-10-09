#!/bin/sh

# Override find files functions
# Remove the ":line" pattern from compiler & grep
unalias ff  2>/dev/null
function ff() {
  set -f
  NAME=name _ff "$(echo $1 | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g')" "${@:2}"
  set +f
}
unalias iff 2>/dev/null
function iff() {
  set -f
  NAME=iname _ff "$(echo $1 | sed -e 's/\([^:]*\):\([0-9]*\)\(:.*\)\?/\1/g')" "${@:2}"
  set +f
}

# Various dev search function helpers
function h()     { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.h|*.hpp"; }
function c()     { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc"; }
function hc()    { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp"; }
function py()    { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.py"; }
function mk()    { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.mk|Makefile"; }
function shell() { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.sh"; }
function ref()   { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.c|*.cpp|*.cc|*.h|*.hpp|*.py|*.mk|Makefile|*.sh"; }
function v()     { _gg "${1}" ${CASE} "${@:3}" "${2:-.}/*.vhd|*.v"; }
alias ih='CASE=-i h'
alias ic='CASE=-i c'
alias ihc='CASE=-i hc'
alias ipy='CASE=-i py'
alias imk='CASE=-i mk'
alias ishell='CASE=-i shell'
alias iref='CASE=-i ref'
alias iv='CASE=-i v'

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
