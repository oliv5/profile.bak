#!/bin/sh

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

# Success display function
msg_success() {
  printf "\33[32m[✔]\33[0m" "$@"
}

# Error display function
msg_error() {
  printf "\33[31m[✘]\33[0m" "$@"
}
