#!/bin/sh
SRC="${1:-.}"
if [ -d "$SRC/drive_c/users" ]; then
    find "$SRC/drive_c/users" -type l -print0 | xargs -r0 -n1 sh -c '
        rm -i "$1" </dev/tty
        mkdir -v "$1"
    ' _
fi
