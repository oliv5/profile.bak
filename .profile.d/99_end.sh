#!/bin/sh

# Call env external profile script
if [ -f ~/.profile.after ]; then
  source ~/.profile.after
fi

# Export user functions
#fct-export
export -f die
