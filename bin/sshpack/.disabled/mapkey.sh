#!/bin/sh
set -x

cat ~/.xmodmaprc
#keycode 115 = , NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol
#keycode 116 = ; NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol NoSymbol

sudo dumpkeys
xev | sed -n 's/.*keycode *\([0-9]\+\)[^,]*, \([^)]\+\)).*$/keycode \1, keysym \2/p'
xmodmap ~/.xmodmaprc
xmodmap -pke
cat /usr/include/X11/keysymdef.h | head -n 200

set +x
