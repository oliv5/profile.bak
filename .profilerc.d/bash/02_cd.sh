#!/bin/bash
if [ -z "$_CD_SBACK_MAX" ]; then
	declare -a _CD_SBACK=()
	export _CD_SBACK_MAX=10
	declare -a _CD_SFORW=()
	export _CD_SFORW_MAX=10
fi

# Stack based cd/back functions
cda()  { builtin cd "$@" && { test -z "${_CD_PUSH}" && { push _CD_SBACK "$OLDPWD" && pkeepq _CD_SBACK $_CD_SBACK_MAX; } || true; }; }
cdb()  { local DIR; pop _CD_SBACK DIR 2>/dev/null && push _CD_SFORW "$PWD" && pkeepq _CD_SFORW $_CD_SFORW_MAX && _CD_PUSH=1 cd "$DIR"; }
cdf()  { local DIR; pop _CD_SFORW DIR 2>/dev/null && push _CD_SBACK "$PWD" && pkeepq _CD_SBACK $_CD_SBACK_MAX && _CD_PUSH=1 cd "$DIR"; }

# Replace cd
cd() { cda "$@"; }

# Clean up all custom mappings
cdu() { unalias cd cda cdb cdf pushd popd 2>/dev/null; unset -f cd cda cdb cdf pushd popd 2>/dev/null; }

# Display stacks
cds() { echo "backward[${#_CD_SBACK[@]}]: ${_CD_SBACK[@]}"; echo "forward[${#_CD_SFORW[@]}]: ${_CD_SFORW[@]}"; }

# Empty stacks
cdc() { _CD_SBACK=(); _CD_SFORW=(); }

# Make and cd
mkcd () { mkdir -p "$@" && cd "$@"; }
