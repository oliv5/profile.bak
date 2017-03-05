#!/bin/sh

# Sudo
alias sudo='su root --'

# Processes
alias pg='pgrep -fl'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }
