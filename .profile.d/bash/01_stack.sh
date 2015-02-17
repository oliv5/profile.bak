#!/bin/bash
# http://www.tldp.org/LDP/abs/html/arrays.html

# Get length
# Call: plen array
plen() {
  #echo "${#array0[@]}"
  eval echo \${#$1[@]}
}

# Push onto stack
# Call: push array elem1 .. elemN
push() {
  #array0[${#array0[@]}]="${@:2}"
  eval "$1=(\"\${$1[@]}\" \"\${@:2}\")"
}

# Add to fifo
# Call: add array elem1 .. elemN
padd() {
  eval "$1=(\"\${@:2}\" \"\${$1[@]}\")"
}

# Pack array removing holes
# Call: pack array
pack() {
  eval "$1=(\${$1[@]})"
}

# Delete n elements
# Call: pdeln array start end
pdeln() {
  for i in $(seq $3 -1 $2); do
    eval unset $1[$i]
  done
  RET=$?
  pack $1
  return $RET
}

# Delete n elements from head
# Call: pdelh array n
pdelh() {
  pdeln $1 0 $(expr ${2:-1} - 1)
}

# Delete n elements from queue
# Call: pdelq array n
pdelq() {
  local LEN=$(eval expr \${#$1[@]})
  eval pdeln $1 $(expr $LEN - ${2:-1}) $(expr $LEN - 1)
}

# Keep n elements from head
# Call: pkeeph array n
pkeeph() {
  pdelq $1 $(eval expr \${#$1[@]} - $2)
}

# Keep n elements from queue
# Call: pkeepq array n
pkeepq() {
  pdelh $1 $(eval expr \${#$1[@]} - $2)
}

# Peek 1 element from stack
# Call: peek array var
peek() {
  eval "$2=\${$1[\${#$1[@]}-1]}"
}

# Peek 1 element from stack
# and return it with echo
# Call: peekl array
peekl() {
  eval echo \${$1[\${#$1[@]}-1]}
}

# Peek n elements from stack
# Call: peekn array start end
peekn() {
  local LEN=$(eval expr \${#$1[@]})
  pcopy $1 $2 $LEN-$3 $LEN
}

# Extract elements from array
# Call: pcopy array1 array2 start end
pcopy() {
  #echo array1=("${array0[@]:$2:$3}")
  eval "$2=(\"\${$1[@]:\$3:\$4}\")"
}

# Pop from stack
# Call: pop array var
pop() {
  peek $1 $2
  pdelq $1
  #eval unset $1[\${#$1[@]}-1]
  #eval "$1=(\${$1[@]})"
}

# Pop 1 element from stack
# Call: pop array var
popl() {
  peek $1 PEEK
  pdelq $1
  echo $PEEK
}

# Pop n elements from stack
# Call: popn array var n
popn() {
  peekn $1 $2 $3
  pdelq $1 $3
  #for i in $(seq 1 $3); do
  #  eval unset $1[\${#$1[@]}-1]
  #done
  #eval "$1=(\${$1[@]})"
}

# Replace in array 1 matching element
# Call: psed array regex replacement
psed() {
  #array0=("${array0[@]/$2/$3}")
  eval "$1=(\"\${$1[@]/\$2/\$3}\")"
}

# Replace in array all matching elements
# Call: psedg array regex replacement
psedg() {
  #array0=("${array0[@]//$2/$3}")
  eval "$1=(\"\${$1[@]//\$2/\$3}\")"
}

# Replace in array 1 element from front of list
# Call: psedf array regex replacement
psedf() {
  #array0=("${array0[@]/#$2/$3}")
  eval "$1=(\"\${$1[@]/#\$2/\$3}\")"
}

# Replace in array 1 element from back of list
# Call: psedb array regex replacement
psedb() {
  #array0=("${array0[@]/%$2/$3}")
  eval "$1=(\"\${$1[@]/%\$2/\$3}\")"
}

# Display list
pdisp() {
  eval echo "\${$1[@]}"
}

# clear list
pclear() {
  eval "$1=()"
}

# Set list
pset() {
  eval "$1=(${@:2})"
}

# Declare list
alias pdeclare='declare -a'

# Sanity test function
psanity() {
  pexec() {
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
