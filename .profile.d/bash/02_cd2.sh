#!/bin/bash
if [ -z "$g_backward_stack_maxsize" ]; then
	declare -a g_forward_stack=()
	export g_forward_stack_maxsize=10
fi

# Pushd/popd based cd/back functions
cda { ${ENV_PUSH:-true} || return 0 && builtin cd "$@" && builtin pushd -n "$OLDPWD" >/dev/null 2>&1; }
cdb { while ! builtin popd >/dev/null 2>&1; do builtin popd -n >/dev/null 2>&1; done && push g_forward_stack "$OLDPWD" && pkeepq g_forward_stack $g_forward_stack_maxsize && ENV_PUSH=false cd .; }
cdf { pop g_forward_stack DIR >/dev/null 2>&1 && cd "$DIR"; }

# Replace cd
cd() { cda "$@"; }

# Clean up all custom mappings
cdc() { unalias cd cda cdb cdf pushd popd 2>/dev/null; unset -f cd cda cdb cdf pushd popd 2>/dev/null; }

# Display stacks
cds() { echo -n "Backward: ";dirs; echo "Forward: $g_forward_stack"; }
