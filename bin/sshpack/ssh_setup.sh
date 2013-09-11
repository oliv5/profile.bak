#!/bin/bash

# Load ssh functions
function ssh-setup() {
  source ssh_config.sh
  source ssh_func.sh
  source ssh_pack.sh
}

# Main
export SSHPACK_PATH="${ENV_PATH}"
ssh-setup
