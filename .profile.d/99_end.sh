#!/bin/sh

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"

# Export user functions
#fct-export-all

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE_DONE=$ENV_CNT
