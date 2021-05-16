#!/bin/sh
PREFIX="$1"
WINEPREFIX="$2"
if [ -d "$PREFIX" ] && [ -d "$WINEPREFIX" ]; then
    PREFIX="$(readlink -f "$PREFIX")"
    WINEPREFIX="$(readlink -f "$WINEPREFIX")"
    export PATH="$PREFIX/bin:$PATH"
    export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
    export WINEPREFIX
    echo "Setting PATH=$PATH"
    echo "Setting LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "Setting WINEPREFIX=$WINEPREFIX"
fi
