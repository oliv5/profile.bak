#!/bin/bash
declare -a g_backward_stack=()
g_backward_stack_maxsize=10
declare -a g_forward_stack=()
g_forward_stack_maxsize=10

# First implementation cd/back functions
#function cda_old() { export PWD_0="$PWD"; builtin cd "$@"; }
#function cdb_old() { cd "$PWD_0"; }

# Stack based cd/back functions
function cda()  { _PWD="$PWD"; builtin cd "$@" && ${PUSH:-true} && push g_backward_stack "$_PWD" && pkeepq g_backward_stack $g_backward_stack_maxsize; }
function cdb()  { push g_forward_stack "$_PWD" && pkeepq g_forward_stack $g_forward_stack_maxsize; pop g_backward_stack DIR 2>/dev/null && PUSH=false cd "$DIR"; }
function cdf()  { push g_backward_stack "$_PWD" && pkeepq g_backward_stack $g_backward_stack_maxsize; pop g_forward_stack DIR 2>/dev/null && PUSH=false cd "$DIR"; }

# Alias (do not put this before cdb function definition)
alias scd='echo "PWD[${#g_backward_stack[@]}]: ${g_backward_stack[@]}"'
alias cd='cda'

