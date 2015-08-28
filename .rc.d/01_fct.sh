#!/bin/sh

################################
# Check fct exists
fct_exists() {
  true ${1:?No fct specified}
  set | grep -G "^$1\s*()" >/dev/null 2>&1
  # The following code returns false when
  # function is overriden by an existing alias
  #[ "$(type -t $1)" = "function" ]
}

# Get fct definition
fct_def() {
  true ${1:?No fct specified}
  if fct_exists "$1"; then
    type $1 | tail -n +2
  fi
}

# Get fct content
fct_content() {
  true ${1:?No fct specified}
  if fct_exists "$1"; then
    type $1 | head -n -1 | tail -n +4
  fi
}

# Append to fct
fct_append() {
  local FCT=${1:?No fct specified}; shift
  eval "${FCT}() { $(fct_content $FCT); $@; }"
}

# Preppend to fct
fct_prepend() {
  local FCT=${1:?No fct specified}; shift
  eval "${FCT}() { $@; $(fct_content $FCT); }"
}

# Check alias/fct collision
fct_collision() {
  for ALIAS in $(alias | awk -F '[= ]' '{print $2}'); do
    [ "${1:-$ALIAS}" = "$ALIAS" ] &&
    fct_exists "$ALIAS" && 
    echo "$ALIAS"
  done
}

################################
# Computations
min() { echo $(($1<$2?$1:$2)); }
max() { echo $(($1>$2?$1:$2)); }
lim() { max $(min $1 $3) $2; }
isint() { expr 2 "*" "$1" + 1 >/dev/null 2>&1; }

# Hex to signed int
hex2int() {
  local MAX=$((1<<${1:?No width specified...}))
  local MEAN=$(($(($MAX>>1))-1))
  local RES=$(printf "%d" "$2")
  [ $RES -gt $MEAN ] && RES=$((RES-MAX))
  echo $RES
}

# Hex to signed 32
hex2int32() {
  hex2int 32 "$@"
}

# Hex to signed 64
hex2int64() {
  hex2int 64 "$@"
}

# Hex to unsigned 64
hex2uint32() {
  printf "%d" "$1"
}

# Hex to unsigned 64
uint2hex() {
  printf "0x%x" "$1"
}

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}

################################
# Return a string with uniq words
alias str_uniqw='str_uniq " " " "'
str_uniq() {
  local _IFS="${1:- }"
  local _OFS="${2}"
  shift 2
  #printf -- '%s\n' $@ | sort -u | xargs
  printf -- "$@" | awk -vRS="$_IFS" -vORS="$_OFS" '!seen[$0]++ {str=str$1ORS} END{sub(ORS"$", "", str); printf "%s\n",str}'
}
