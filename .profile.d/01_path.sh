#!/bin/sh

# Prepend to path
path-prepend() {
  local DIR
  for DIR in "$@"; do
    #if ! [[ "$PATH" =~ "${DIR}" ]] && [[ -d "$DIR" ]]; then
    if [ -d "$DIR" ] && ! (echo "$PATH" | grep "${DIR}" >/dev/null); then
      export PATH="${DIR}${PATH:+:$PATH}"
    fi
  done
}

# Append to path
path-append() {
  local DIR
  for DIR in "$@"; do
    #if ! [[ "$PATH" =~ "${DIR}" ]] && [[ -d "$DIR" ]]; then
    if [ -d "$DIR" ] && ! (echo "$PATH" | grep "${DIR}" >/dev/null); then
      export PATH="${PATH:+$PATH:}${DIR}"
    fi
  done
}

# Cleanup path
path-cleanup() {
  #export PATH="${PATH//\~/${HOME}}"
  #export PATH="${PATH//.:/}"
  export PATH="$(echo "$PATH" | sed -e 's|~|'"${HOME}"'|g' -e 's|\.\:||g')"
}

# Main
unalias path-append 2>/dev/null
eval path-append /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin
unalias path-prepend 2>/dev/null
eval path-prepend "$HOME/bin" "$HOME/bin/profile"

