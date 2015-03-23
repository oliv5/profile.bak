#!/bin/sh

# Prepend to path
path_prepend() {
  local DIR
  for DIR; do
    #if ! [[ "$PATH" =~ "${DIR}" ]] && [[ -d "$DIR" ]]; then
    if [ -d "$DIR" ] && ! (echo "$PATH" | grep "${DIR}" >/dev/null); then
      export PATH="${DIR}${PATH:+:$PATH}"
    fi
  done
}

# Append to path
path_append() {
  local DIR
  for DIR; do
    #if ! [[ "$PATH" =~ "${DIR}" ]] && [[ -d "$DIR" ]]; then
    if [ -d "$DIR" ] && ! (echo "$PATH" | grep "${DIR}" >/dev/null); then
      export PATH="${PATH:+$PATH:}${DIR}"
    fi
  done
}

# Cleanup path
path_cleanup() {
  #PATH="${PATH//\~/${HOME}}"; PATH=${PATH//.:/}
  #PATH="$(echo "$PATH" | sed -r 's|~|'"${HOME}"'|g; s|\.\:||g' | awk -v RS=':' -v ORS=":" '!a[$1]++')"
  PATH="$(echo "$PATH" | sed -r 's|~|'"${HOME}"'|g; s|\.\:||g' | awk 'NF && !x[$0]++' RS='[:|\n]' ORS=':')"
  export PATH
}
