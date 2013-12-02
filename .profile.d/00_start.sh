#!/bin/bash

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE_D=$ENV_CNT

# Call env external profile script
if [ -x ~/.localsrc ]; then
  source ~/.localsrc
fi

# Add to path function
function addpath() {
  for DIR in "$@"; do
    if ! [[ $PATH =~ $DIR ]]; then
      export PATH="$PATH:$DIR"
    fi
  done
}

# Die function
die() {
  printf '%s\n' "${@:-abort...}"
  exit 128
}
