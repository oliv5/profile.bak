#!/bin/sh
# https://developer.android.com/studio/command-line/adb
# https://github.com/jackpal/Android-Terminal-Emulator/wiki/Android-Shell-Command-Reference
# http://delphi.org/2013/11/installing-and-running-android-apps-from-command-line/

# Su/sudo
#su() { (eval /system/bin/su root -- /system/bin/sh -c \""$@"\" & wait $!); }
#sudo() { (eval /system/bin/su root -- /system/bin/sh -c \""$@"\" & wait $!); }
! command -v sudo >/dev/null &&
  alias sudo='su root --'

# Process monitoring
alias pg='pgrep -fl'
alias ps='/system/xbin/ps'
alias psg='ps -ef | grep -i'
alias ppid='ps -o pid,ppid | grep'
alias sps='sudo /system/xbin/ps -ef'
alias spsg='sudo "/system/xbin/ps -ef | grep"'
alias sppid='sudo "/system/xbin/ps -o pid,ppid,comm | grep"'

# Aliases/functions helpers
alias lsg='ls | grep -i'
alias llg='ll | grep -i'
gpp() { getprop ${@:+| grep $@}; }

# Setup apps
alias install='pm install -r'
alias uninstall='pm uninstall -k'

# Permissions management
alias add_perm='pm grant'
alias rm_perm='pm revoke'

# Apps management
start_app(){ am start -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
stop_app(){ am force-stop "${1:?No package name specified...}"; }

# Services management
start_svc(){ am startservice "${1:?No package name specified...}/${2:?No service name specified...}" ${3:+--user "$3"}; }
stop_svc(){ am stopservice "${1:?No package name specified...}" ${3:+--user "$3"}; }
