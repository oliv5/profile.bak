#!/bin/sh
# https://github.com/jackpal/Android-Terminal-Emulator/wiki/Android-Shell-Command-Reference
# http://delphi.org/2013/11/installing-and-running-android-apps-from-command-line/

# Sudo
alias sudo='su root --'

# Processes
alias pg='pgrep -fl'
alias psg='ps -def | grep -i'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'

# Aliases/functions helpers
gpp() { getprop ${@:+| grep $@}; }

# Setup apps
alias install='install -r'
alias uninstall='pm uninstall -k'

# Apps management
start(){ am start -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
stop(){ am force-stop "${1:?No package name specified...}"; }

# Services management
start_svc(){ am startservice "${1:?No package name specified...}/${2:?No service name specified...}" ${3:+--user "$3"}; }
stop_svc(){ am stopservice "${1:?No package name specified...}" ${3:+--user "$3"}; }