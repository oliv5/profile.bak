#!/bin/bash

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
  command -v checkbashisms 2>&1 >/dev/null || die "checkbashisms not found..."
  find "${1:-.}" -name "${2:-*.sh}" -exec sh -c 'checkbashisms {} 2>/dev/null || ([ $? -ne 2 ] && echo "checkbashisms {}")' \;
}
