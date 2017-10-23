#!/bin/sh

################################
# Computations
min() { echo $(($1<$2?$1:$2)); }
max() { echo $(($1>$2?$1:$2)); }
lim() { max $(min $1 $3) $2; }
isint() { expr 2 "*" "$1" + 1 >/dev/null 2>&1; }
alias avg="awk '{a+=\$1} END{print a/NR}'"

# Conversion to (unsigned) integer using printf
_int() {
  local MAX="${1:?No maximum value specified...}"
  shift
  for RES; do
    [ $RES -ge $MAX ] && RES=$((RES-2*MAX))
    echo $RES
  done
}
alias int='int32'
alias int8='_int $((1<<7))'
alias int16='_int $((1<<15))'
alias int32='_int $((1<<31))'
alias int64='_int $((1<<63))'
alias uint='uint32'
alias uint8='_int $((1<<8))'
alias uint16='_int $((1<<16))'
alias uint32='_int $((1<<32))'
alias uint64='_int $((1<<64))'

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}

# Hexwrite byte
# $1: file
# $2: offset
# $3: dec value
hexwrite() {
  printf '\\x%s' "$3" | dd of="$1" bs=1 seek="$2" count=1 conv=notrunc &> /dev/null
}

# Sum pipe input
alias sum="awk 'BEGIN{a=0}{a=a+\$0}END{print a}'"

# Make a sum of all inputs
add() {
  local RES=0
  for I; do
    RES=$(($RES+$I))
  done
  echo $RES
}

# Substract ($2+$3+...$n) to $1
sub() {
  local RES=${1:-0}
  shift $(($#>0?1:0))
  for I; do
    RES=$(($RES-$I))
  done
  echo $RES
}

################################
# Floating point operations
# See http://unix.stackexchange.com/questions/40786/how-to-do-integer-float-calculations-in-bash-or-other-languages-frameworks
#
#echo "$((20.0/7))"
#awk "BEGIN {print (20+5)/2}"
#zcalc
#bc <<< 20+5/2
#bc <<< 'scale=4;20+5/2'
#expr 20 + 5
#calc 2 + 4
#node -pe 20+5/2  # Uses the power of JavaScript, e.g. : node -pe 20+5/Math.PI
#echo 20 5 2 / + p | dc 
#echo 4 k 20 5 2 / + p | dc 
#perl -E "say 20+5/2"
#python -c "print 20+5/2"
#python -c "print 20+5/2.0"
#clisp -x "(+ 2 2)"
#lua -e "print(20+5/2)"
#php -r 'echo 20+5/2;'
#ruby -e 'p 20+5/2'
#ruby -e 'p 20+5/2.0'
#guile -c '(display (+ 20 (/ 5 2)))'
#guile -c '(display (+ 20 (/ 5 2.0)))'
#slsh -e 'printf("%f",20+5/2)'
#slsh -e 'printf("%f",20+5/2.0)'
#tclsh <<< 'puts [expr 20+5/2]'
#tclsh <<< 'puts [expr 20+5/2.0]'
#sqlite3 <<< 'select 20+5/2;'
#sqlite3 <<< 'select 20+5/2.0;'
#echo 'select 1 + 1;' | sqlite3 
#psql -tAc 'select 1+1'
#R -q -e 'print(sd(rnorm(1000)))'
#r -e 'cat(pi^2, "\n")'
#r -e 'print(sum(1:100))'
#smjs
#jspl
