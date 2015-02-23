#!/bin/bash

################################
# List user functions
fct_ls() {
  declare -F | cut -d" " -f3
}

# Export user functions from script
fct_export() {
  export -f "$@"
}

# Export all user functions
fct_export_all() {
  export -f $(fct-ls)
}

# Remove function
fct_unset() {
  unset -f "$@"
}

# Print fct content
fct_content() {
  type ${1:?No fct name given...} 2>/dev/null | tail -n+4 | head -n-1
}

# Create fct aliases with - instead of _ character
fct_alias() {
  # Note: cannot use while here, alias not set out of the while !?
  for FCT in $(fct-ls | grep -E "^[^_].+_.+"); do 
    alias $(echo $FCT | tr '_' '-')="$FCT"
  done
}

# Remove fct aliases with - instead of _ character
fct_unalias() {
  # Note: cannot use while here, alias not set out of the while !?
  for FCT in $(fct-ls | grep -E "^[^_].+_.+"); do 
    unalias $(echo $FCT | tr '_' '-')
  done
}

# Convert fct names with "-" into "_"
fct_convert() {
  sed -E 's@^([^\-\(]+)-([^\-\(]+\(\))@\1_\2@' "$@"
}

################################
# Get script directory
pwd_get() {
  echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
}

################################
# Check bashism in scripts
bash_checkbashisms() {
  command -v checkbashisms 2>&1 >/dev/null || die "checkbashisms not found..."
  find "${1:-.}" -name "${2:-*.sh}" -exec sh -c 'checkbashisms {} 2>/dev/null || ([ $? -ne 2 ] && echo "checkbashisms {}")' \;
}
