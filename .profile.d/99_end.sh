#!/bin/sh

# Call env external profile script
if [ -f ~/.localerc ]; then
  source ~/.localerc
fi

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE_D=$ENV_CNT
