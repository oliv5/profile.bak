#!/bin/bash

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
