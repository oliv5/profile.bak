#!/bin/sh

# Sudo
alias sudo='su root --'

# Processes
alias psgx='ps -x | grep -i'
alias psg='ps -def | grep -i'
alias pg='pgrep -fl'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }
