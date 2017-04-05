#!/bin/sh

# Find prefix
wine_findprefix() {
  local SRC="${1:-.}"; shift
  find "$SRC" -path "*/drive_c/users" -type d "$@"
}

# Wine setup
wine_setup() {
  local PREFIX="${1:?No prefix specified...}"
  local DST="${2:-$HOME/.wineprefix}/$PREFIX"
  local ARCH="${3:-win32}"
  if [ ! -d "$DST" ]; then
      WINEPREFIX="$DST" WINEARCH="$ARCH" winecfg
      WINEPREFIX="$DST" winetricks --gui
  fi
  # Wine links to home directory
  wine_rmlinks "$DST"
  # DirectX 9
  echo "Setup DirectX 9 ? (y/n)"; read _REPLY
  if [ "$_REPLY" = "y" -o "$_REPLY" = "Y" ]; then
      WINEPREFIX="$DST" winetricks quartz directx9_36
  fi
}

# Wine remove links to home directory
wine_rmlinks() {
  find "${1:-.}" -path "*/drive_c/users" -type d -print0 | 
    xargs -I {} -r0 -n1 find "{}" -type l -print0 | 
      xargs -r0 -n1 sh -c '
          echo "Convert link \"$1\" to plain directory ?"
          rm -i "$1" </dev/tty &&
          mkdir "$1"
      ' _
}
