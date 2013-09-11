#!/bin/bash

declare -x array0=("11" "22" "33 44")
echo "${array0[@]}"
echo "${#array0[@]}"

function pcopy() {
  #echo array1=("${array0[@]:$2:$3}")
  eval "$2=(\"\${$1[@]:\$3:\$4}\")"
}

function plen() {
  #echo "${#array0[@]}"
  eval echo \${#$1[@]}
}

function peekm() {
  local LEN=$(eval expr \${#$1[@]})
  pcopy $1 $2 $LEN-$3 $LEN
}

function popm() {
  peekm $1 $2 $3
  for i in $(seq 1 $3); do
    eval unset $1[\${#$1[@]}-1]
  done
}

echo "plen"
plen array0
echo "pcopy"
pcopy array0 array1 1 2
echo "${array1[@]}"
echo "${#array1[@]}"
echo "peekm"
peekm array0 array1 2
echo "${array1[@]}"
echo "${#array1[@]}"
echo "popm"
popm array0 array1 2
echo "${array1[@]}"
echo "${#array1[@]}"
echo "${array0[@]}"
echo "${#array0[@]}"

exit

# Replace in array
function psed() {
  #array0=("${array0[@]/$2/$3}")
  eval "$1=(\"\${$1[@]/\$2/\$3}\")"
}

# Global replace in array
function psedg() {
  #array0=("${array0[@]//$2/$3}")
  eval "$1=(\"\${$1[@]//\$2/\$3}\")"
}


function psedf() { # from front of all elements
  #array0=("${array0[@]/#$2/$3}")
  eval "$1=(\"\${$1[@]/#\$2/\$3}\")"
}

function psedb() { # from back of all elements
  #array0=("${array0[@]/%$2/$3}")
  eval "$1=(\"\${$1[@]/%\$2/\$3}\")"
}

echo "psed"
psedb array0 "2" "a"
echo "${array0[@]}"
echo "${#array0[@]}"

exit

function peek() {
  eval echo \${$1[\${#$1[@]}-1]}
}

function pop() {
  peek $1
  eval unset $1[\${#$1[@]}-1]
}

echo "pop"
pop array0 "55" "66 77"
echo "${array0[@]}"
echo "${#array0[@]}"

exit

function push() {
  #array0[${#array0[@]}]="${@:2}"
  #NOK eval $1[\${#$1[@]}]="\${@:2}"

  #array1=("${array0[@]}")
  #eval "$1=(\${$1[@]} \${@:2})"
  eval "$1=(\"\${$1[@]}\" \"\${@:2}\")"
}

push array0 "55" "66 77"
echo "push"
echo "${array0[@]}"
echo "${#array0[@]}"
exit

function push() {
  #myArray=("$@")
  #echo "${myArray[@]}"
  echo "$@"
}

function push2() {
  LAST=$(eval expr "\${#$1[@]}")
  eval '$1[$LAST]="$2"'
}

declare -x array0=("11" "22" "33 44")
echo "${#array0[@]}"
array0=($(push "${array0[@]}" "55"))
#array0=($(push "${array0[@]}" "55"))
echo "${array0[@]}"
echo "${#array0[@]}"
echo "${array0[0]}"
#push2 "array0" "55"
#echo "${array0[@]}"
#echo "${#array0[@]}"
exit

function pop() {
  LAST=$(eval expr "\${#$1[@]} - 1")
  eval echo \${$1[$LAST]}
  eval unset $1[$LAST]
  eval export $1
}

function plen() {
  eval expr \${#$1[@]}
}

val=$(pop array0)
echo $val
echo "${array0[@]}"
echo "${#array0[@]}"
exit

array0=("11" "22" "33 44")
# Just when you are getting the feel for this . . .
array6=( "${array0[@]#*11}" )
echo ${array6[0]}
echo ${array6[1]}
echo ${array6[2]}
echo ${#array6[@]}
echo "Elements in array6:  ${array6[@]}"
echo

function indirect1() {
  y=$1
  echo $y
  echo ${!y}
  echo \$$y
}
myvar=23
indirect1 myvar
echo

function test3() {
  myArray=("$@")
  echo ${#myArray[@]}
  echo ${myArray[0]}
  echo ${myArray[1]}
  echo ${myArray[2]}
  echo ${myArray[3]}
}
array0=("11" "22" "33 44")
test3 "${array0[@]}" "zz"
echo ${#array0[@]}
exit

function test2() {
  echo "$1"
  echo "$2"
}

function indirect() {
  y=$1
  echo $y
  echo ${!y}
  echo \$$y
  return

  echo Test
  array=eval '\${$1[@]}'
  echo ${array[0]}
  echo ${array[1]}
echo ${array[2]}
echo ${#array[@]}
  echo
  return

  echo push2
  eval "expr \"\$$1\""
  eval "expr \$$1"
  eval echo \$$1
  eval echo \${$1[@]}
  return

  #eval "expr \"\${$1[@]}\""
  eval "echo \${$1[@]}"
  eval "echo \${$1[0]}"
  eval "echo \${$1[1]}"
  eval "echo \${$1[2]}"
  eval "expr \${#$1[@]}"
  eval "echo \${#$1[@]}"
  echo $(expr "\${$1[@]}")
  echo
}

array0=(11 22 "33 44")
var=1
test2 "${!array0}" "${!var}"
exit

array0=(11 22 "33 44")
array1=("${array0[@]}")
echo ${array1[@]}
echo ${array1[0]}
echo ${array1[1]}
echo ${array1[2]}
exit


# -----------------

function pinit() {
  array0=("$@")
}

function push() {
  array0[${#array0[@]}]="$@"
  echo ${array0[@]}
}

function peek() {
  echo ${array0[${1:-@}]}
}

function pop() {
  LEN=${#array0[@]}-1
  echo ${array0[$LEN]}
  unset array0[$LEN]
}

function pget() {
  echo ${array0[@]}
}

function plen() {
  echo ${#array0[@]}
}

function plist() {
  echo ${array0[@]:$1:$2}
}

function prep() {
  echo ${array0[@]/$1/$2}
}

function prepall() {
  echo ${array0[@]//$1/$2}
}

# Test stack
function stacktest() {
  push "ee"
  push "ff"
  push "ee"
  push "gg"
  pop
  peek 1
  pget
  plen
  prep "ee" "aa"
}
