#!/bin/sh
PREFIX="${1:?No prefix specified...}"
DST="${2:-$HOME/.wineprefix}/$PREFIX"
ARCH="${3:-win32}"
if [ ! -d "$DST" ]; then
    WINEPREFIX="$DST" WINEARCH="$ARCH" winecfg
    WINEPREFIX="$DST" winetricks --gui
fi
# DirectX 9
echo "Setup DirectX 9 ? (y/n)"; read _REPLY
if [ "$_REPLY" = "y" -o "$_REPLY" = "Y" ]; then
    WINEPREFIX="$DST" winetricks quartz directx9_36
fi
