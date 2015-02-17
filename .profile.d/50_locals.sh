#!/bin/sh
# Call local profile scripts
if [ -x "$HOME/.localrc" ]; then
  export ENV_LOCALRC=$((ENV_CNT=ENV_CNT+1))
  . "$HOME/.localrc"
fi

if [ -x "$HOME/.profile.local" ]; then
  export ENV_PROFILE_LOCAL=$((ENV_CNT=ENV_CNT+1))
  . "$HOME/.profile.local"
fi

export ENV_PROFILE_LOCAL_D=$((ENV_CNT=ENV_CNT+1))
for i in "$HOME/.profile.local.d/"*.sh ; do
  if [ -x "$i" ]; then
    . "$i"
  fi
done
