#!/bin/sh

# This function prints each argument wrapped in single quotes
# (separated by spaces).  Any single quotes embedded in the
# arguments are escaped.
#
shell_quote() {
    # run in a subshell to protect the caller's environment
    (
        sep=''
        for arg in "$@"; do
            sqesc=$(printf '%s\n' "${arg}" | sed -e "s/'/'\\\\''/g")
            printf '%s' "${sep}'${sqesc}'"
            sep=' '
        done
    )
}

# Put parameters into variables
# $1 = string with a list of all variables names
# ${@:2} = all parameters values
# The last variable is set to the remaining values
getargs(){
	local VAR="_ARGS"
	#local IFS=" ;,"
	for VAR in $1; do
		eval "$VAR=\"$2\""
		shift
	done

	REM=""
	eval "$VAR=\"$(shell_quote "$@")\""
	return

	set -vx
	eval "unset $VAR"
	#TOTO=""
	for VAL in "$@"; do
	#	TOTO="${TOTO:+$TOTO }\"$VAL\""
		#eval "$VAR=\"\${$VAR:+\$$VAR }\\\"\$VAL\\\"\""
		eval "$VAR=\"\${$VAR:+\$$VAR }\\\"\$VAL\\\"\""
	done
	set +vx
	return

	#WRONG: loose quotes !?
	#eval "$VAR=\"$@\""
	set -vx
	echo "Count=$#"
	eval "$VAR=\"\\\'$@\\\'\""
	set +vx
	return

	set -vx
	shift
	for VAL in "$@"; do
		eval "$VAR=\"\$$VAR \\\"$VAL\\\"\""
	done
	set +vx
}

echo "Test local IFS"
OLDIFS=$(printf 'toto \n\t')
IFS=$(printf 'toto \n\t')
[ "$IFS" = "$OLDIFS" ] && echo "IFS ok";
getargs
[ "$IFS" = "$OLDIFS" ] && echo "IFS ok";
IFS=$(printf ' \n\t')

echo ----------------------------
read

echo "Test getargs"
getargs "a b c" "a b" c d "e f" g
echo "a=$a"
echo "b=$b"
echo "c=$c"
IFS=$(printf ' \n\t')
set $c
echo "\$1=$1"
echo "\$2=$2"
echo "\$3=$3"
echo "\$4=$4"
echo "\$c count=$#"
for f in $c; do
	echo $f
done

echo ----------------------------
read

# Shift and return the remaining parameters
shiftargs() {
	shift $1; shift
	echo "$@"
}

count() {
	echo count
	echo $#
	for f; do
		echo $f
	done
}

echo "Test shiftargs return string"
IFS=$(printf ' \n\t')
for f in $(shiftargs 2 "a b" c d "e f" g); do
	echo $f
done
count $(shiftargs 2 "a b" c d "e f" g)
count "$(shiftargs 2 "a b" c d "e f" g)"

echo ----------------------------
read

# Shift and set the remaining parameters in variable
shiftargs() {
	local VAR="${1:-_ARGS}"
	shift $2
	eval "$VAR=\'$@\'"
}

echo "Test 2nd shiftargs"
set -vx
set ""
shiftargs ARGS 2 "a b" c d "e f" g
set +vx

set "$ARGS"
echo "$@"
echo "\$1=$1"
echo "\$2=$2"
echo "\$3=$3"
echo "Count=$#"

echo ----------------------------
read
