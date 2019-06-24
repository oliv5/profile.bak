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
alias llg='ls -la | grep -i'
alias sp='setprop'
alias gp='getprop'
gppg() { getprop ${@:+| grep $@}; }

# Setup apps
alias install='pm install -r'
alias uninstall='pm uninstall -k'

# Permissions management
alias perm_add='pm grant'
alias perm_rm='pm revoke'

# Apps management
app_start(){ am start -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
app_restart(){ am start -S -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
app_stop(){ am force-stop "${1:?No package name specified...}"; }

# Start/stop app from package
alias pkg_ls='pm list packages -f | cut -f 2 -d "=" | sort'
pkg_start() {
    local PACKAGE="${1:?No package name specified...}"
    local ACTIVITY="${2:-.MainActivity}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am start -n "{}/$ACTIVITY"
}
pkg_stop() {
    local PACKAGE="${1:?No package name specified...}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am force-stop -n "{}"
}

# Services management
svc_start(){ am startservice "${1:?No package name specified...}/${2:?No service name specified...}" ${3:+--user "$3"}; }
svc_stop(){ am stopservice "${1:?No package name specified...}" ${3:+--user "$3"}; }

# Unlock screen
alias screen_unlock='input keyevent 82'

# Lock screen
alias screen_lock='input keyevent 6; input keyevent 26'

# Open default browser
alias browser='input keyevent 23'

# Volume
alias volp='input keyevent 24'
alias voln='input keyevent 25'

# Go to home screen
alias home='input keyevent 3'

# Start/stop clock app
alias clock_start='am start com.google.android.deskclock'
alias clock_stop='am force-stop com.google.android.deskclock'

# Manage wifi
alias wifi_mgr='am start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings'
alias wifi_status='am start -n com.android.settings/.wifi.WifiStatusTest'
alias wifi_on='su root -- svc wifi enable'
alias wifi_off='su root -- svc wifi disable'

# Manage mobile data
alias data_on='su root -- svc data enable'
alias data_off='su root -- svc data disable'
alias data_eco_off='su root -- cmd netpolicy set restrict-background false'
alias data_eco_off='su root -- cmd netpolicy set restrict-background true'

# Manage bluetooth
alias bt_enable='su root -- svc bluetooth enable'
alias bt_disable='su root -- svc bluetooth disable'

# Manage usb
alias usb_get_fct='su root -- svc usb getFunction'
alias usb_set_fct='su root -- svc usb setFunction'

# Manage nfc
alias nfc_enable='su root -- svc nfc enable'
alias nfc_disable='su root -- svc nfc disable'

# Manage power
alias pwr_stayon='su root -- svc power stayon'
alias pwr_shutdown='su root -- svc power shutdown'
alias pwr_reboot='su root -- svc power reboot'
