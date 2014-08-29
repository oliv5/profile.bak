#!/bin/bash
declare -a g_forward_stack=()

# Pushd/popd based cd/back functions
function cda { builtin cd "$@" && builtin pushd -n "$OLDPWD" >/dev/null 2>&1; }
function cdb { builtin popd >/dev/null 2>&1 && push g_forward_stack "$OLDPWD" && cd .; }
function cdf { pop g_forward_stack DIR >/dev/null 2>&1 && cd "$DIR"; }

# Aliases
alias cd='cda'
alias scd='echo -n "Backward: ";dirs; echo "Forward: $g_forward_stack"'
