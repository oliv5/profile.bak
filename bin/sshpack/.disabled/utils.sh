#!/bin/bash
# http://www.tldp.org/LDP/abs/html/
# http://www.skybert.net/unix/bash/serious-programming-in-bash
# https://github.com/bmc/lib-sh

###################

# Use of set to assign $1 $2 $3 ...
IFS=":"; set $(grep $USER /etc/passwd)
echo -e "Login :\t$1\nNom :\t$5\nID :\t$3\nGroup :\t$4\nShell :\t$7"

###################

# Exit hook
function my_exit_hook() {
  echo "Cleaning up after you"
}

trap my_exit_hook EXIT

###################

# Hash maps/dictionaries
my_map=(
  ["first_name"]="John"
  ["last_name"]="Doe"
)

for el in ${!my_map[@]}; do
    echo $el":" ${my_map[$el]}
done

###################
#Arrays

fruit_array=("apples" "oranges" "bananas" "peaches" "papayas")

# Iterate with index
for (( i = 0; i < ${#fruit_array[@]}; i++ )); do
    echo $i "="  ${fruit_array[$i]}
done

# Iterate no index
for fruit in ${fruit_array[@]}; do
  echo $fruit
done

# Iterate from a starting index
for fruit in ${fruit_array[@]:1}; do
  echo $fruit "(skipped the first one)"
done

# Iterate on a range
for fruit in ${fruit_array[@]:1:3}; do
  echo $fruit "(skipped the first and last ones)"
done

# Create array from command
tarballs=($(ls /my/dir/*.tar.gz))

#Array copy
array0=(11 22 "33 44")
array1=("${array0[@]}")

#################
Map keyboard

xev | sed -n 's/.*keycode *\([0-9]\+\)[^,]*, \([^)]\+\)).*$/keycode \1, keysym \2/p'
xmodmap ~/.xmodmaprc
xmodmap -pke
cat /usr/include/X11/keysymdef.h | head -n 200
