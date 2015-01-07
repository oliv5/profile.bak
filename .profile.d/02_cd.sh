#!/bin/bash
if [ -z "$g_backward_stack_maxsize" ]; then
	declare -a g_backward_stack=()
	export g_backward_stack_maxsize=10
	declare -a g_forward_stack=()
	export g_forward_stack_maxsize=10
fi

# First implementation cd/back functions
#function cda_old() { export PWD_0="$PWD"; builtin cd "$@"; }
#function cdb_old() { cd "$PWD_0"; }

# Stack based cd/back functions
function cda()  { builtin cd "$@" && ${ENV_PUSH:-true} || return 0 && push g_backward_stack "$OLDPWD" && pkeepq g_backward_stack $g_backward_stack_maxsize; }
function cdb()  { pop g_backward_stack DIR 2>/dev/null && push g_forward_stack "$PWD" && pkeepq g_forward_stack $g_forward_stack_maxsize && ENV_PUSH=false cd "$DIR"; }
function cdf()  { pop g_forward_stack DIR 2>/dev/null && push g_backward_stack "$PWD" && pkeepq g_backward_stack $g_backward_stack_maxsize && ENV_PUSH=false cd "$DIR"; }

# Replace cd
function cd() { cda "$@"; }

# Clean up all custom mappings
function cdc() { unalias cd cda cdb cdf pushd popd 2>/dev/null; unset -f cd cda cdb cdf pushd popd 2>/dev/null; }

# Display stacks
alias scd='echo "backward[${#g_backward_stack[@]}]: ${g_backward_stack[@]}"; echo "forward[${#g_forward_stack[@]}]: ${g_forward_stack[@]}"'
