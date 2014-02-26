#!/bin/bash
declare -a g_pwd_stack=()
g_pwd_stack_maxsize=10

# First implementation cd/back functions
function cda_old() { export PWD_0="$PWD"; builtin cd "$@"; }
function cdb_old() { cd "$PWD_0"; }

# Stack based cd/back functions
function cda()  { _PWD="$PWD"; builtin cd "$@" && ${PUSH:-true} && push g_pwd_stack "$_PWD" && pkeepq g_pwd_stack $g_pwd_stack_maxsize; }
function cdb()  { pop g_pwd_stack DIR 2>/dev/null && PUSH=false cd "$DIR"; }

# Alias (do not put this before cdb function definition)
alias scd='echo "PWD[${#g_pwd_stack[@]}]: ${g_pwd_stack[@]}"'
alias cd='cda'
