#!/bin/sh

# Processes
alias psg='ps -x | grep -i'
alias pg='pgrep -fl'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }
