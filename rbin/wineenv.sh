#!/bin/sh
PREFIX="$1"
WINEPREFIX="$2"
if [ -d "$PREFIX" ] && [ -d "$WINEPREFIX" ]; then
    PREFIX="$(readlink -f "$PREFIX")"
    export PATH="$PREFIX/bin:$PATH"
    export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
    export WINEPREFIX="$(readlink -f "$WINEPREFIX")"
    if [ -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
        export LD_LIBRARY_PATH="/lib:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
    else
        export LD_LIBRARY_PATH="/lib/i386-linux-gnu:$LD_LIBRARY_PATH"
    fi
    echo "Setting PATH=$PATH"
    echo "Setting LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "Setting WINEPREFIX=$WINEPREFIX"
fi
