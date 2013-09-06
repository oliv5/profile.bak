#!/bin/bash
# http://www.tldp.org/LDP/abs/html/arrays.html

# Get length
# Call: plen array
function plen() {
  #echo "${#array0[@]}"
  eval echo \${#$1[@]}
}

# Push onto stack
# Call: push array elem1 .. elemN
function push() {
  #array0[${#array0[@]}]="${@:2}"
  eval "$1=(\"\${$1[@]}\" \"\${@:2}\")"
}

# Concat array removing holes
# Call: pcat array
function pcat() {
  eval "$1=(\${$1[@]})"
}

# Delete n elements
# Call: pdeln array start end
function pdeln() {
  for i in $(seq $3 -1 $2); do
    eval unset $1[$i]
  done
  pcat $1
}

# Delete n elements from head
# Call: pdelh array n
function pdelh() {
  pdeln $1 0 $(expr ${2:-1} - 1)
}

# Delete n elements from queue
# Call: pdelq array n
function pdelq() {
  local LEN=$(eval expr \${#$1[@]})
  eval pdeln $1 $(expr $LEN - ${2:-1}) $(expr $LEN - 1)
}

# Keep n elements from head
# Call: pkeeph array n
function pkeeph() {
  pdelq $1 $(eval expr \${#$1[@]} - $2)
}

# Keep n elements from queue
# Call: pkeepq array n
function pkeepq() {
  pdelh $1 $(eval expr \${#$1[@]} - $2)
}

# Peek 1 element from stack
# Call: peek array var
function peek() {
  eval "$2=\${$1[\${#$1[@]}-1]}"
}

# Peek 1 element from stack
# and return it with echo
# Call: peekl array
function peekl() {
  eval echo \${$1[\${#$1[@]}-1]}
}

# Peek n elements from stack
# Call: peekn array start end
function peekn() {
  local LEN=$(eval expr \${#$1[@]})
  pcopy $1 $2 $LEN-$3 $LEN
}

# Extract elements from array
# Call: pcopy array1 array2 start end
function pcopy() {
  #echo array1=("${array0[@]:$2:$3}")
  eval "$2=(\"\${$1[@]:\$3:\$4}\")"
}

# Pop from stack
# Call: pop array var
function pop() {
  peek $1 $2
  pdelq $1
  #eval unset $1[\${#$1[@]}-1]
  #eval "$1=(\${$1[@]})"
}

# Pop n elements from stack
# Call: popn array var n
function popn() {
  peekn $1 $2 $3
  pdelq $1 $3
  #for i in $(seq 1 $3); do
  #  eval unset $1[\${#$1[@]}-1]
  #done
  #eval "$1=(\${$1[@]})"
}

# Replace in array 1 matching element
# Call: psed array regex replacement
function psed() {
  #array0=("${array0[@]/$2/$3}")
  eval "$1=(\"\${$1[@]/\$2/\$3}\")"
}

# Replace in array all matching elements
# Call: psedg array regex replacement
function psedg() {
  #array0=("${array0[@]//$2/$3}")
  eval "$1=(\"\${$1[@]//\$2/\$3}\")"
}

# Replace in array 1 element from front of list
# Call: psedf array regex replacement
function psedf() {
  #array0=("${array0[@]/#$2/$3}")
  eval "$1=(\"\${$1[@]/#\$2/\$3}\")"
}

# Replace in array 1 element from back of list
# Call: psedb array regex replacement
function psedb() {
  #array0=("${array0[@]/%$2/$3}")
  eval "$1=(\"\${$1[@]/%\$2/\$3}\")"
}

# Sanity test function
function psanity() {
  function pexec() {
    echo "$@"
    $@
  }
  array=(0 1 2 3 4 5 6); echo array; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec plen array; echo
  array=(0 1 2 3 4 5 6); pexec pdeln array 0 0; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pdeln array 3 5; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pdeln array 6 6; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pdelh array 2; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pdelq array 2; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pkeeph array 2; echo ${array[@]}; echo
  array=(0 1 2 3 4 5 6); pexec pkeepq array 2; echo ${array[@]}; echo
}
