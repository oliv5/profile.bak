#!/bin/sh
SRDIR="/etc"
DSTDIR="/var/backups/system"
command git -C "$SRCDIR" bundle create "$DSTDIR/$(basename "$SRDIR").bundle.$(uname -n).$(date +%Y%m%d-%H%M%S).git" --all --tags --remotes
