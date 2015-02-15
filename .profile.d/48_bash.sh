#!/bin/bash
#[ "${SHELL##*/}" = "bash" ] || return 1

################################
# Prevent Ctrl-D exit session
export IGNOREEOF=1

# History
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL=ignoreboth
export HISTIGNORE='&:[ ]*'	# Avoid duplicates in history

################################
# List user functions
fct-ls() {
  declare -F | cut -d" " -f3 | egrep -v "^_"
}

# Export user functions from script
fct-export() {
export -f "$@"
}

# Export all user functions
fct-export-all() {
  export -f $(fct-ls)
}

# Remove function
fct-unset() {
  unset -f "$@"
}

# Print fct content
fct-content() {
  type ${1:?No fct name given...} 2>/dev/null | tail -n+4 | head -n-1
}

################################
# Get script directory
pwd-get() {
  echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
}

################################
# Check bashism in scripts
bash-checkbashisms() {
  find "${1:-.}" -name "${2:-*.sh}" -exec sh -c 'checkbashisms {} 2>/dev/null || echo "checkbashisms {}"' \;
}
