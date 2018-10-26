#!/bin/sh

# Return a string with uniq words
alias str_uniqw='str_uniq " " " "'
str_uniq() {
  local _IFS="${1:- }"
  local _OFS="${2}"
  shift 2
  #printf -- '%s\n' $@ | sort -u | xargs
  #printf -- "$@"
  printf '%s' "$@" | awk -vRS="$_IFS" -vORS="$_OFS" '!seen[$0]++ {str=str$1ORS} END{sub(ORS"$", "", str); printf "%s\n",str}'
}

# To lower
alias tolower='str_low'
str_low() {
  echo "${@}" | tr "[:upper:]" "[:lower:]"
}
str_lowfirst() {
  echo "${@}" | sed 's/.*/\l&/'
}

# To upper
alias toupper='str_upper'
str_up() {
  echo "${@}" | tr "[:lower:]" "[:upper:]"
}
str_upfirst() {
  echo "${@}" | sed 's/.*/\u&/'
}

# Check if string have the given prefix
str_prefix() {
  local PATTERN="$1"
  shift
  for FILE; do
    [ "$FILE" == "${FILE#$PATTERN}" ] && return 1
  done
  return 0
}

# Check if string have the given suffix
str_suffix() {
  local PATTERN="$1"
  shift
  for FILE; do
    [ "$FILE" == "${FILE%$PATTERN}" ] && return 1
  done
  return 0
}

# Trim
str_trim() {
  echo "$@" | sed -e 's/\(^\s*\|\s*$\)//g'
}
str_triml() {
  echo "$@" | sed -e 's/^\s*//g'
}
str_trimr() {
  echo "$@" | sed -e 's/\s*$//g'
}

# Length
str_len() {
  for STR; do
    echo ${#STR}
  done
}
