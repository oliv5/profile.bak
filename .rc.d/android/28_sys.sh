#!/bin/sh

# Su/sudo
unalias sudo 2>/dev/null
if ! command -v sudo >/dev/null; then
  sudo() { su root -c "PATH=\"$PATH\"; "$@""; stty sane 2>/dev/null; }
fi

# Process monitoring
alias pg='pgrep -fl'
alias psg='ps -ef | grep -i'
alias ppid='ps -o pid,ppid | grep'
alias sps='sudo ps -ef'
alias spsg='sudo ps -ef | grep'
alias sppid='sudo ps -o pid,ppid,comm | grep'

# Aliases/functions helpers
alias lsg='ls | grep -i'
alias llg='ls -la | grep -i'
alias sp='setprop'
alias gp='getprop'
gppg() { getprop ${@:+| grep $@}; }

# Load external ADB API if exists
if [ -r "/sdcard/.adbrc" ]; then
  . /sdcard/.adbrc
fi

