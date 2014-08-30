#!/bin/bash

# Trap interrupts and exit
trap 'echo Interrupted after $retry trials; exit;' SIGINT SIGTERM

# Init
if [[ $1 =~ ^-?[0-9]+$ ]]; then
  RETRY_MAX=$1
  CMD="${@:2}"
else
  unset RETRY_MAX
  CMD="$@"
fi
retry=0

# Loop
false; while [ $? -ne 0 ]; do
  [[ ! -z "$RETRY_MAX" && $retry -ge $RETRY_MAX ]] && break
  retry=$(($retry+1))
  #[[ $retry < 0 ]] && retry=0
  eval $CMD
done

# Done
echo "Ended after $retry trials"
