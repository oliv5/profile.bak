#!/bin/bash
if [ -z "$_cd_sback_maxsize" ]; then
	declare -a _cd_sback=()
	export _cd_sback_maxsize=10
	declare -a _cd_sforw=()
	export _cd_sforw_maxsize=10
fi

# First implementation cd/back functions
#function cda_old() { export PWD_0="$PWD"; builtin cd "$@"; }
#function cdb_old() { cd "$PWD_0"; }

# Stack based cd/back functions
cda()  { builtin cd "$@" && { test -z "${_CD_PUSH}" && push _cd_sback "$OLDPWD" && pkeepq _cd_sback $_cd_sback_maxsize; }; }
cdb()  { local DIR; pop _cd_sback DIR 2>/dev/null && push _cd_sforw "$PWD" && pkeepq _cd_sforw $_cd_sforw_maxsize && _CD_PUSH=1 cd "$DIR"; }
cdf()  { local DIR; pop _cd_sforw DIR 2>/dev/null && push _cd_sback "$PWD" && pkeepq _cd_sback $_cd_sback_maxsize && _CD_PUSH=1 cd "$DIR"; }

# Replace cd
cd() { cda "$@"; }

# Clean up all custom mappings
cdu() { unalias cd cda cdb cdf pushd popd 2>/dev/null; unset -f cd cda cdb cdf pushd popd 2>/dev/null; }

# Display stacks
cds() { echo "backward[${#_cd_sback[@]}]: ${_cd_sback[@]}"; echo "forward[${#_cd_sforw[@]}]: ${_cd_sforw[@]}"; }

# Empty stacks
cdc() { _cd_sback=(); _cd_sforw=(); }

# Make and cd
mkcd () { mkdir -p "$@" && cd "$@"; }
