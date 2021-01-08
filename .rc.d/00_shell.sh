#!/bin/bash

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
quote() { [ $# -gt 0 ] && printf '"%s" ' "$@"; return 0; }
arg_quote() {
  local SEP=''
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
    for A; do [ "$A" = "$Q" ] && return 0; done
    return 1
}

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
# Success display function
msg_success() {
  printf "\33[32m[✔]\33[0m" "$@"
}

# Error display function
msg_error() {
  printf "\33[31m[✘]\33[0m" "$@"
}

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
err() { return ${1:-0}; }

################################
# Directory management
dir_empty() {
  test -z "$(find "$1" -mindepth 1 -printf X -quit)"
}

################################
# Create an unamed pipe
mkpipe() {
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

# Returns the status or the first piped command
# https://unix.stackexchange.com/a/16709
pipe_status() {
  # Ex: ( exec 4>&1; ERR=$({ { (echo 'toto titi'; false); echo $? >&3; } | grep toto; } 3>&1 >&4); exec 4>&-; echo "Errcode=$ERR" )
  local CMD1="${1:?No command 1 specified...}"
  local CMD2="${2:?No command 2 specified...}"
  local PIPE1="${3:-3}"
  local PIPE2="${4:-4}"
  eval "exec ${PIPE2}>&1"
  local ERR=$(eval "{ { ($CMD1); echo \$? >&${PIPE1}; } | $CMD2; } ${PIPE1}>&1 >&${PIPE2}")
  eval "exec ${PIPE2}>&-"
  return $ERR
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

# Unalias a script commands
cmd_unalias() {
  for FILE; do
    for FCT in $(awk -F'(' '/\w\s*\(\)/ {print $1}' "$FILE"); do
      unalias "$CMD" 2>/dev/null
    done
  done
}

# Unalias all existing commands
cmd_unalias_all() {
  for CMD in $(set | grep " () $" | cut -d" " -f1); do
    unalias "$CMD" 2>/dev/null
  done
}

################################
# Run a command silently
alias noerror='2>/dev/null'
alias noerr='2>/dev/null'
alias noout='>/dev/null'
alias silent='>/dev/null 2>&1'
alias silent2='nohup'

# Run a command and filter stdout by another one
filter_stdout() {
  { eval "$1" 2>&1 1>&3 | eval "$2" 1>&2; } 3>&1
}

# which replacement when missing
cmd_exists which ||
which() {
  local IFS=:
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
ansi_export_codes() {
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
}
ansi_codes() {
  local NC='\033[0m' # No Color
  local BLACK='\033[0;30m'
  local BLUE='\033[0;34m'
  local GREEN='\033[0;32m'
  local CYAN='\033[0;36m'
  local RED='\033[0;31m'
  local PURPLE='\033[0;35m'
  local ORANGE='\033[0;33m'
  local LGRAY='\033[0;37m'
  local DGRAY='\033[1;30m'
  local LBLUE='\033[1;34m'
  local LGREEN='\033[1;32m'
  local LCYAN='\033[1;36m'
  local LRED='\033[1;31m'
  local LPURPLE='\033[1;35m'
  local YELLOW='\033[1;33m'
  local WHITE='\033[1;37m'
  for F; do
    eval echo "\${$F}"
  done
}
ansi_echo() {
  local CODE="${1:-NC}"; shift
  echo -e "$(ansi_codes "$CODE")$*$(ansi_codes "NC")"
}
ansi_printf() {
  local CODE="${1:-NC}"; shift
  printf "$(ansi_codes "$CODE")$*$(ansi_codes "NC")"
}

# Strip ANSI codes
alias ansi_strip='sed "s/\x1b\[[0-9;]*m//g"'

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
