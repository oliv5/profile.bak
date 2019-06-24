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
alias psg='ps -ef | grep -i'
alias ppid='ps -o pid,ppid | grep'
alias sps='sudo ps -ef'
alias spsg='sudo "ps -ef | grep"'
alias sppid='sudo "ps -o pid,ppid,comm | grep"'

# Aliases/functions helpers
alias lsg='ls | grep -i'
alias llg='ll | grep -i'
alias sp='setprop'
alias gp='getprop'
gppg() { getprop ${@:+| grep $@}; }

# Setup apps
alias install='pm install -r'
alias uninstall='pm uninstall -k'

# Permissions management
alias add_perm='pm grant'
alias rm_perm='pm revoke'

# Apps management
start_app(){ am start -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
restart_app(){ am start -S -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
stop_app(){ am force-stop "${1:?No package name specified...}"; }

# Start/stop app from package
start_pkg() {
    local PACKAGE="${1:?No package name specified...}"
    local ACTIVITY="${2:-.MainActivity}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am start -n "{}/$ACTIVITY"
}
stop_pkg() {
    local PACKAGE="${1:?No package name specified...}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am force-stop -n "{}"
}

# Services management
start_svc(){ am startservice "${1:?No package name specified...}/${2:?No service name specified...}" ${3:+--user "$3"}; }
stop_svc(){ am stopservice "${1:?No package name specified...}" ${3:+--user "$3"}; }
