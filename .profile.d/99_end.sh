#!/bin/sh

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"

# Export user functions
#fct-export-all
