#!/bin/sh

# Call env external profile script
if [ -f ~/.localerc ]; then
  source ~/.localerc
fi

# Export user functions
fct-export
