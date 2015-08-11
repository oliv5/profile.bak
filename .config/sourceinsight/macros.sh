#!/bin/sh
PREFIX="$HOME/.wine-sourceinsight"
SRC="$HOME/.config/sourceinsight/macros"
DST="$PREFIX/drive_c/users/$USER/My Documents/Source Insight/Projects/Base"
URL="http://www.sourceinsight.com/public/macros/"

# Sample macros
echo "Download sample macros at $URL"
echo wget -r --no-parent --no-clobber --reject "index.html*" --no-directories --directory-prefix="$SRC/sample"  "$URL"
echo

# Set the macro files in the Base project directory
ln -sv "$SRC/"*.em "$DST/"
ln -sv "$SRC/sample/"*.em "$DST/"
#cp -v "$SRC/"*.em "$DST/"

# Warning
echo
echo "Note: you have to add macro files to your project or the base project,"
echo"then source them, for SI to finally load them"

