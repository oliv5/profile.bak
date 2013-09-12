#!/bin/bash

# Load ssh functions
function ssh-source() {
  source ssh_config.sh
  source ssh_func.sh
}

# Main
export SSHPACK_PATH="${ENV_PATH}"
ssh-source
