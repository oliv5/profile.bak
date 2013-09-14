#!/bin/bash

# Load ssh functions
function ssh-source() {
  source ssh_config.sh
  source ssh_func.sh
}

# Main
export SSHPACK_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH="$PATH:$SSHPACK_PATH"
ssh-source
