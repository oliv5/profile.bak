#!/bin/sh
# Load only in android
[ -z "$ANDROID_ROOT" ] && return 1

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }
