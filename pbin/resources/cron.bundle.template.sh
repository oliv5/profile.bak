#!/bin/sh
SRCDIR="${1:-/etc}"
DSTDIR="${2:-/var/backups/system}"
GPGKEY="${3}"
BUNDLE="$DSTDIR/$(basename "$SRCDIR").bundle.$(uname -n).$(date +%Y%m%d-%H%M%S).git"
command -p git -C "$SRCDIR" bundle create "$BUNDLE" --all --tags --remotes
if [ ! -z "$GPGKEY" ]; then
    command -p gpg -v --batch --no-default-recipient --recipient "$GPGKEY" --trust-model always --encrypt "$BUNDLE" && (
	command -p shred -v "$BUNDLE" || command -p wipe -q -f "$BUNDLE" || command -p rm "$BUNDLE"
    )
fi
