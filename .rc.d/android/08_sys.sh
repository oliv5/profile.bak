#!/bin/sh

# Processes
ps -x >/dev/null 2>&1 &&
  alias psg='ps -x | grep -i' ||
  alias psg='ps -def | grep -i'
alias pg='pgrep -fl'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }
