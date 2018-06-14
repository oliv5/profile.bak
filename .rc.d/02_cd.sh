#!/bin/sh

# Basic implementation of cd/back/forward functions
cda() { command cd "$@"; }
cdb() { command cd "$OLDPWD"; }
cdf() { cdb "$@"; }

# Replace cd
cd() { cda "$@"; }

# Clean up all custom mappings
cdu() { unalias cd cda cdb cdf 2>/dev/null; unset -f cd cda cdb cdf 2>/dev/null; }

# Make and cd
mkcd () { mkdir -p "$@" && cd "$@"; }

# Quick cd
gcd() { cda *"$1"*"$2"*"$3"*"$4"*"$5"*"$6"*"$7"*"$8"*"$9"*; }
