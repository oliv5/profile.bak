#!/bin/bash
declare -a g_backward_stack=()
export g_backward_stack_maxsize=10
declare -a g_forward_stack=()
export g_forward_stack_maxsize=10

# First implementation cd/back functions
#function cda_old() { export PWD_0="$PWD"; builtin cd "$@"; }
#function cdb_old() { cd "$PWD_0"; }

# Stack based cd/back functions
function cda()  { _PWD="$PWD"; builtin cd "$@" && ${PUSH:-true} && push g_backward_stack "$_PWD" && pkeepq g_backward_stack $g_backward_stack_maxsize; }
function cdb()  { pop g_backward_stack DIR 2>/dev/null && push g_forward_stack "$PWD" && pkeepq g_forward_stack $g_forward_stack_maxsize && PUSH=false cd "$DIR"; }
function cdf()  { pop g_forward_stack DIR 2>/dev/null && push g_backward_stack "$PWD" && pkeepq g_backward_stack $g_backward_stack_maxsize && PUSH=false cd "$DIR"; }

# Alias (do not put this before cdb function definition)
alias scd='echo "backward[${#g_backward_stack[@]}]: ${g_backward_stack[@]}"; echo "forward[${#g_forward_stack[@]}]: ${g_forward_stack[@]}"'
alias cd='cda'
