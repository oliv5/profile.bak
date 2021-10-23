#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
quote() { [ $# -gt 0 ] && printf '"%s" ' "$@"; return 0; }
arg_quote() {
  local SEP=''
  local ARG
  for ARG; do
    SQESC=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
    printf '%s' "${SEP}'${SQESC}'"
    SEP=' '
  done
}

# Right trim shell parameters. Adds quotes
arg_rtrim() {
  local IFS=$'\n\t '
  local LAST="$(($#-$1))"
  local ARG
  for ARG in $(seq 2 $LAST); do 
    eval ARG="\${$ARG}"
    ARG=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
    printf '%s' "'${ARG}' "
  done
}

# Left trim shell parameters. Adds quotes
arg_ltrim() {
  command shift ${1:-1} >/dev/null 2>&1
  arg_quote "$@"
}

# Concat parameters separated by a fixed delimiter
arg_concat() {
  local DELIM="${1:?No delimiter defined...}"
  shift
  local ARG
  for ARG; do
    printf '%s %s ' "$DELIM" "$ARG"
  done
}

# Last shell parameter
alias arg_last='command shift $(($#-1)) >/dev/null 2>&1'

# Get last in list
last() {
  shift $(($#-1))
  echo "$1"
}
lastn() {
  shift $(($#-$1-1))
  echo "$1"
}

# Is in list?
is_in() {
  [ $# -lt 2 ] && return 0
  local Q="$1"
  shift
  local A
  for A; do [ "$A" = "$Q" ] && return 0; done
  return 1
}

# Save & restore shell parameters
arg_save_var() { local _VAR_="${1:-__}"; [ $# -ge 1 ] && shift; local _VAL_="$(arg_quote "$@")"; eval "$_VAR_=\"$_VAL_\""; }
alias arg_save='__="$(arg_quote "$@")"'
alias arg_reset='arg_save; set --'
alias arg_restore='eval set -- "$__"'

################################
# https://stackoverflow.com/questions/18186929/differences-between-login-shell-and-interactive-shell
# http://www.tldp.org/LDP/abs/html/intandnonint.html

# Returns true for interactive shells
shell_isinteractive() {
  # Test whether stdin exists
  [ -t "0" ] || ! [ -p /dev/stdin ]
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
# Other method: shift 2>/dev/null || set --
# Other method: shift $(min $# number)
# Other method: [ $# -ge number ] && shift number || shift $#
alias shift1='command shift 1 2>/dev/null'
alias shift2='command shift 2 2>/dev/null || set --'
alias shift3='command shift 3 2>/dev/null || set --'
alias shift4='command shift 4 2>/dev/null || set --'
alias shift5='command shift 5 2>/dev/null || set --'
alias shift6='command shift 6 2>/dev/null || set --'
alias shift7='command shift 7 2>/dev/null || set --'
alias shift8='command shift 8 2>/dev/null || set --'
alias shift9='command shift 9 2>/dev/null || set --'

# Get script path
shell_script() {
  if [ -n "$BASH_VERSION" ]; then echo "${BASH_SOURCE[0]}"; else
  if [ "$OSTYPE" = *darwin* ]; then greadlink -f "$0"; else readlink -f "$0"; fi; fi
}
shell_path() {
  if [ -n "$BASH_VERSION" ]; then (builtin cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); else
  if [ "$OSTYPE" = *darwin* ]; then greadlink -f "$(dirname "$0")"; else readlink -f "$(dirname "$0")"; fi; fi
}

# Open shell with no ASLR. Set ADDR_NO_RANDOMIZE personality (man sys/personality.h) to all children.
# Same as echo 0 | tee /proc/sys/kernel/randomize_va_space (0=no ASLR, 1=only shared lib, 2=global)
shell_noaslr() {
  setarch "$(uname -m)" -R "$SHELL"
}

# Swap IFS temporarily
shell_ifs() {
  local IFS="${1:?No IFS specified...}"
  shift
  $@ # execute in current environment. No quotes, or IFS is not applied.
}

################################
# Die function
die() {
  local ERRCODE="${1:-1}"
  shift
  printf "$@"
  shell_isinteractive && {
    echo "Die cannot exit the main shell. Press ctrl-c to stop."
    read
    return $ERRCODE
  } || exit $ERRCODE;
}

# Set error code
error() { return ${1:-0}; }
err() { return ${1:-0}; }

################################
# Directory management
dir_empty() {
  test -z "$(find "$1" -mindepth 1 -printf X -quit)"
}

################################
# Get error status of piped commands:
# option #1: bash set -o pipefail and ${PIPESTATUS[0]}
# option #2: use mispipe (sudo apt install mispipe)
# option #3: use named pipes
# https://stackoverflow.com/questions/17757039/equivalent-of-pipefail-in-dash-shell

# Create an unamed pipe
# Input is a stream number > 2
mkpipe() {
  local P
  for P; do
    # Create a temporary named pipe
    PIPE="$(mktemp -u)"
    mkfifo -m 600 "$PIPE"
    # Attach to file descriptor in rw mode "<>"
    eval "exec $P<>\"$PIPE\""
    # Unlink the named pipe
    rm "$PIPE"
  done
}

# Close an unamed pipe
rmpipe() {
  local P
  for P; do
    eval "exec $P>&-"
  done
}

# Pipe multiple writers into a single reader
# Same as bash process substitution
# "reader <(writer1) <(writer2)"
pipe_reader() {
  local READER="${1:?Reader command not specified...}"
  shift
  local DIR="$(mktemp -d)"
  local W
  for W in $(seq $#); do
    mkfifo -m 600 "$DIR/$W"
  done
  for W in $(seq $#); do
    eval "$1" > "$DIR/$W" &
    shift
  done
  eval "$READER" "$DIR"/*
  rm -r "$DIR"
}
# Pipe a single writer into multiple readers
pipe_writer() {
  local WRITER="${1:?Writer command not specified...}"
  shift
  local DIR="$(mktemp -d)"
  local R
  for R in $(seq $#); do
    mkfifo -m 600 "$DIR/$R"
  done
  for R in $(seq $#); do
    eval "$R" < "$DIR/$R" &
    shift
  done
  eval "$WRITER" | tee "$DIR"/* >/dev/null
  rm -r "$DIR"
}

# Custom mispipe using redirects
# Executes 2 cmds in a pipe & returns the status of the first one
# https://unix.stackexchange.com/a/16709
mispipe() {
  # Ex: ( exec 4>&1; ERR=$({ { (echo 'toto titi'; false); echo $? >&3; } | grep toto; } 3>&1 >&4); exec 4>&-; echo "Errcode=$ERR" )
  local CMD1="${1:?No command 1 specified...}"
  local CMD2="${2:?No command 2 specified...}"
  local PIPE1="${3:-3}"
  local PIPE2="${4:-4}"
  exec ${PIPE2}>&1
  local ERR=$(eval "{ { ("$CMD1"); echo \$? >&${PIPE1}; } | "$CMD2"; } ${PIPE1}>&1 >&${PIPE2}")
  exec ${PIPE2}>&-
  return $ERR
}

################################
# Cmd exist test
cmd_exists() {
  local CMD
  for CMD; do
    command -v "$CMD" >/dev/null 2>&1 || return 1
  done
  return 0
}

# Cmd unset
cmd_unset() {
  unalias $* 2>/dev/null || true
  unset -f $* 2>/dev/null
}

# Unalias a script commands
cmd_unalias() {
  local FILE
  local FCT
  for FILE; do
    for FCT in $(awk -F'(' '/\w\s*\(\)/ {print $1}' "$FILE"); do
      unalias "$CMD" 2>/dev/null || true
    done
  done
}

# Unalias all existing commands
cmd_unalias_all() {
  local CMD
  for CMD in $(set | grep " () $" | cut -d" " -f1); do
    unalias "$CMD" 2>/dev/null || true
  done
}

################################
# Verbose run
verbose() { echo "$@" >&2 && "$@"; }

# Silent run
alias noerror='2>/dev/null'
alias noerr='2>/dev/null'
alias noout='>/dev/null'
alias silent='>/dev/null 2>&1'

# Run a command and filter stdout by another one
filter_stdout() {
  { eval "$1" 2>&1 1>&3 | eval "$2" 1>&2; } 3>&1
}

# which replacement when missing
cmd_exists which ||
which() {
  local IFS=:
  local DIR
  [ $# -gt 0 ] &&
    for DIR in $PATH; do
      ls -1 "$DIR/$1" 2>/dev/null && return 0
    done
  return 1
}

################################
# EINTR retry fct
#http://unix.stackexchange.com/questions/16455/interruption-of-system-calls-when-a-signal-is-caught
eintr() {
  local EINTR=4
  eval "$@"
  while [ $? -eq $EINTR ]; do
    eval "$@"
  done
}

################################
# Attach terminal to process
# https://unix.stackexchange.com/questions/31824/how-to-attach-terminal-to-detached-process
# Alternative: reptyr
shell_attach() {
  PID="${1:?No PID specified...}"
  STDIN="${2}"
  STDOUT="${3}"
  GDBINIT="$(mktemp)"
  rm "$GDBINIT" 2>/dev/null
  if [ -n "$STDIN" ]; then
    echo "call close(0)" >> "$GDBINIT"
    echo "call open(\"$STDIN\", 0600)" >> "$GDBINIT"
    [ ! -f "$STDIN" ] && mkfifo "$STDIN"
  fi
  if [ -n "$STDOUT" ]; then
    echo "call close(1)" >> "$GDBINIT"
    echo "call open(\"$STDOUT\", 0400)" >> "$GDBINIT"
    touch "$STDOUT"
  fi
  echo "continue" >> "$GDBINIT"
  echo "quit" >> "$GDBINIT"
  sudo sh -c "gdb -p \"$PID\" -nh -nx -x \"$GDBINIT\""
}

################################
# Implement a basic lock (simple but with a race condition flaw)
shell_block_take() {
  local FILE="${1:?No lock file specified...}"
  if [ -e "${FILE}" ] && kill -0 "$(cat "${FILE}")"; then
    return 1
  fi
  trap 'rm -f "${FILE}"; exit' INT TERM EXIT
  echo $$ > "${FILE}"
}
shell_block_release() {
  trap '' INT TERM EXIT
  rm -f "${FILE}"
}

#~ Traditional form using flock
#~ exec 9> /tmp/mylockfile || return 1
#~ flock 9 || return 2
#~ trap "exec 9>&-; flock -u 9; rm -f /tmp/mylockfile; trap '' INT TERM EXIT; exit" INT TERM EXIT
#~ # ...

# Convenient form using flock
#~ (
#~   flock 9
#~   # ...
#~ ) 9>/tmp/mylockfile

# Implement locks with flock
shell_flock_take() {
  local FILE="${1:?No lock file specified...}"
  local DESCR="${2:-9}" # dash cannot open more than 10 file handlers
  local TIMEOUT="$3" # 0=fail immediatly; if not specified, then wait until lock available
  local TYPE="${4:--x}" # -x = exclusive (write), -s = shared (read)
  exec "$DESCR"> "$FILE" || return 1
  flock ${TIMEOUT:+-w "$TIMEOUT"} ${TYPE} "$DESCR" || return 2
  trap "shell_flock_release '$FILE' '$DESCR'; trap '' INT TERM EXIT; exit" INT TERM EXIT
  return 0
}
shell_flock_release() {
  local FILE="${1:?No lock file specified...}"
  local DESCR="${2:-9}"
  flock -u "$DESCR"
  exec "$DESCR"<&-
  rm -f "$FILE"
}

################################
# Return shell option string
# Restore with eval
shell_getopts() {
  set +o
  shopt -p 2>/dev/null
}
