#!/bin/sh
SRCDIR="${1:-/etc}"
DSTDIR="${2:-/var/backups/system}"
GPGKEY="${3}"
BUNDLE="$DSTDIR/$(basename "$SRCDIR").bundle.$(uname -n).$(date +%Y%m%d-%H%M%S).git"
command git -C "$SRCDIR" bundle create "$BUNDLE" --all --tags --remotes
if [ ! -z "$GPGKEY" ]; then
    gpg -v --batch --no-default-recipient --recipient "$GPGKEY" --trust-model always --encrypt "$BUNDLE" && (
	wipe -q -f "$BUNDLE" || rm "$BUNDLE"
    )
fi
