#!/bin/sh
PREFIX="${PREFIX:-$HOME/.wine-sourceinsight}"
DIR="$PREFIX/drive_c/Program Files (x86)/Source Insight 3"
if [ ! -d "$DIR" ]; then
	DIR="$PREFIX/drive_c/Program Files/Source Insight 3"
fi
WINEPREFIX="$PREFIX" wine "$DIR/Insight3.exe" "$@" 2>/dev/null &
