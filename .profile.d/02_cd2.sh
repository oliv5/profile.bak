#!/bin/bash
declare -a g_forward_stack=()

# Pushd/popd based cd/back functions
function cda { builtin cd "$@" && builtin pushd -n "$OLDPWD" >/dev/null; }
function cdb { builtin popd >/dev/null && push g_forward_stack "$OLDPWD"; }
function cdf { pop g_forward_stack DIR 2>/dev/null && cda "$DIR"; }

# Aliases
alias cd='cda'
alias scd='echo -n "Backward: ";dirs; echo "Forward: $g_forward_stack"'
