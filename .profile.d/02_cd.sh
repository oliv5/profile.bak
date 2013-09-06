#!/bin/bash
declare -a g_pwd_stack=()
g_pwd_stack_maxsize=10

# Alias
alias scd='echo "PWD[${#g_pwd_stack[@]}]: ${g_pwd_stack[@]}"'
alias cd='cda'

# cd function
function cdaa() { export PWD_0="${PWD}"; builtin cd "$@"; }
function cda() { push g_pwd_stack ${PWD}; builtin cd "$@" || pdelq g_pwd_stack; pkeepq g_pwd_stack $g_pwd_stack_maxsize; }

# back function
function cdbb() { cd "${PWD_0}"; }
function cdb()  { pop g_pwd_stack DIR 2>/dev/null; builtin cd "$DIR"; }
