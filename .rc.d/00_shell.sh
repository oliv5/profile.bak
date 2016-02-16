#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
#
arg_quote() {
  local SEP=''
  for ARG; do
    SQESC=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
    printf '%s' "${SEP}'${SQESC}'"
    SEP=' '
  done
}

# Right trim shell parameters
arg_rtrim() {
  local IFS=$'\n\t '
  local LAST="$(($#-$1))"
  for ARG in $(seq 2 $LAST); do 
    eval ARG="\${$ARG}"
    ARG=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
    printf '%s' "'${ARG}' "
  done
}

################################
# https://stackoverflow.com/questions/18186929/differences-between-login-shell-and-interactive-shell
# http://www.tldp.org/LDP/abs/html/intandnonint.html

# Returns true for interactive shells
shell_isinteractive() {
  # Test whether stdin exists
  [ -t "0" ] || [ -p /dev/stdin ]
  # Alternate method
  #case $- in
  #  *i*) return 0;;
  #  *) return 1;;
  #esac
}

# Returns true for login shells
shell_islogin() {
  # Test whether the caller name starts with a "-"
  [ "$(echo "$0" | cut -c 1)" = "-" ]
}

# Few shift aliases to prevent fatal error 
# and eat all arguments when over-shifting
# Other method: shift $(min $# number)
alias shift1='command shift 1 2>/dev/null'
alias shift2='command shift 2 2>/dev/null || set --'
alias shift3='command shift 3 2>/dev/null || set --'
alias shift4='command shift 4 2>/dev/null || set --'
alias shift5='command shift 5 2>/dev/null || set --'
alias shift6='command shift 6 2>/dev/null || set --'
alias shift7='command shift 7 2>/dev/null || set --'
alias shift8='command shift 8 2>/dev/null || set --'
alias shift9='command shift 9 2>/dev/null || set --'

# Alias to get script path
alias shell_script='[ -n "$BASH_VERSION" ] && (builtin cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || readlink -f "$(dirname "$0")"'

################################
# Warn function
warn() {
  [ $# -gt 0 ] && echo "$@" >&2
}

# Die function
die() {
  local ERRCODE="${1:-1}"
  shift
  warn "$@"
  shell_isinteractive && {
    echo "Die cannot exit the main shell. Press ctrl-c to stop."
    read
    return $ERRCODE
  } || exit $ERRCODE;
}

################################
# Cmd exist test
cmd_exists() {
  for CMD; do
    command -v "$CMD" >/dev/null 2>&1 || return 1
  done
  return 0
}

# Cmd unset
cmd_unset() {
  unalias $* 2>/dev/null
  unset -f $* 2>/dev/null
}

################################
# Run a command silently (especially shell fct)
# Note: can use "nohup" when running real prgm
silent() {
  local ARG1="$1"; shift
  $ARG1 $@  >/dev/null 2>&1 &
}

# Run a command and filter stdout by another one
filter_stdout() {
  { eval "$1" 2>&1 1>&3 | eval "$2" 1>&2; } 3>&1
}

# which replacement when missing
cmd_exists which || {
  which() {
    local IFS=:
    [ $# -gt 0 ] &&
      for DIR in $PATH; do
          ls -1 "$DIR/$1" 2>/dev/null && return 0
      done
    return 1
  }
}

################################
# Ansi codes
# http://man7.org/linux/man-pages/man4/console_codes.4.html
# https://en.wikipedia.org/wiki/ANSI_escape_code
#Black        0;30     Dark Gray     1;30
#Blue         0;34     Light Blue    1;34
#Green        0;32     Light Green   1;32
#Cyan         0;36     Light Cyan    1;36
#Red          0;31     Light Red     1;31
#Purple       0;35     Light Purple  1;35
#Brown/Orange 0;33     Yellow        1;33
#Light Gray   0;37     White         1;37
# To use it:
## export RED='\033[0;31m'
## export NC='\033[0m' # No Color
## echo -e "I ${RED}love${NC} Stack Overflow"
## printf "I ${RED}love${NC} Stack Overflow\n"
export NC='\033[0m' # No Color
export BLACK='\033[0;30m'
export BLUE='\033[0;34m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export RED='\033[0;31m'
export PURPLE='\033[0;35m'
export ORANGE='\033[0;33m'
export LGRAY='\033[0;37m'
export DGRAY='\033[1;30m'
export LBLUE='\033[1;34m'
export LGREEN='\033[1;32m'
export LCYAN='\033[1;36m'
export LRED='\033[1;31m'
export LPURPLE='\033[1;35m'
export YELLOW='\033[1;33m'
export WHITE='\033[1;37m'

# Strip ANSI codes
alias rm-ansi='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'
