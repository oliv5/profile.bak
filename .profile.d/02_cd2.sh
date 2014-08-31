#!/bin/bash
declare -a g_forward_stack=()

# Pushd/popd based cd/back functions
function cda { ${PUSH:-true} && builtin cd "$@" && builtin pushd -n "$OLDPWD" >/dev/null 2>&1; }
function cdb { builtin popd >/dev/null 2>&1 && push g_forward_stack "$OLDPWD" && PUSH=false cd .; }
function cdf { pop g_forward_stack DIR >/dev/null 2>&1 && cd "$DIR"; }

# Replace cd, pushd and popd
alias cd='cda'

# Overload pushd and popd functions
function pushd { builtin pushd "$@" >/dev/null 2>&1; }
function popd  { builtin popd  "$@" >/dev/null 2>&1; }

# Display stacks
alias scd='echo -n "Backward: ";dirs; echo "Forward: $g_forward_stack"'
