#!/bin/sh
RETRY=0

# Trap interrupts
trap 'echo Interrupted after $RETRY trials; trap - INT TERM; exit;' INT TERM

# Init - check if $1 is an integer => retry limit
LIMIT=-1
if expr 2 "*" "$1" + 1 > /dev/null 2>&1; then
  LIMIT=$1
  shift
fi
CMD="$@"

# Loop
false; while [ $? -ne 0 ] && [ $LIMIT -le 0 -o $RETRY -ne $LIMIT ]; do
  RETRY=$(($RETRY+1))
  eval "$CMD"
done

# Done - untrap and exit
trap - INT TERM
echo "Ended after $RETRY trials"
