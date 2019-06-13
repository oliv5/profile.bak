#!/bin/sh

# Replace
if [ -n "$BASH_VERSION" ]; then
str_replace() {
  echo "${1//$2/$3}"
}
else
str_replace() {
  echo "$1" | sed -e "s/$2/$3/"
}
fi

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
  for STR; do
    [ "$STR" = "${STR#$PATTERN}" ] && return 1
  done
  return 0
}

# Check if string have the given suffix
str_suffix() {
  local PATTERN="$1"
  shift
  for STR; do
    [ "$STR" = "${STR%$PATTERN}" ] && return 1
  done
  return 0
}

# Check if substring is in string
alias str_isin='str_substring'
str_substring() {
  local STR="$1"
  shift
  case "$*" in
    *${STR}*) return 0;;
  esac
  return 1
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

# Return a string with uniq words
alias str_uniqw='str_uniq " " " "'
str_uniq() {
  local _IFS="${1:- }"
  local _OFS="${2}"
  shift 2
  printf '%s' "$@" | awk -vRS="$_IFS" -vORS="$_OFS" '!seen[$0]++ {str=str$1ORS} END{sub(ORS"$", "", str); printf "%s\n",str}'
}

# Keep only uniq strings in list
str_filter_uniq() {
  { [ $# -gt 0 ] && echo "$@" || cat /dev/stdin; } | 
    awk -vRS="${RS:-\n}" '{cnt[$1]++}END{for(s in cnt){if (cnt[s]==1){print s}}}'
}

# Keep only non-uniq strings in list
str_filter_duplicate() {
  { [ $# -gt 0 ] && echo "$@" || cat /dev/stdin; } | 
    sort | uniq -d
}
