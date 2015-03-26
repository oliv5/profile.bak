#!/bin/sh
REPO="$HOME/.config/sourceinsight"
PREFIX="$HOME/.wine-sourceinsight"
USER_PREFIX="$PREFIX/drive_c/users/$USER"

# Copy the current configuration backup file into our profile
find "$USER_PREFIX" -type f -name "GLOBAL.CF3" -exec cp "{}" "$REPO/GLOBAL.CF3" \;
