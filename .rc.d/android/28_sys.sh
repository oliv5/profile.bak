#!/system/bin/sh
# https://thangamaniarun.wordpress.com/2013/04/19/useful-android-adb-commands-over-usbwi-fi/
# https://developer.android.com/studio/command-line/adb
# https://github.com/jackpal/Android-Terminal-Emulator/wiki/Android-Shell-Command-Reference
# http://delphi.org/2013/11/installing-and-running-android-apps-from-command-line/

# Su/sudo
unalias sudo 2>/dev/null || true
if ! command -v sudo >/dev/null; then
  sudo() { su root -c "PATH=\"$PATH\"; "$@""; stty sane 2>/dev/null; }
fi

# Execute a cmd with seLinux off
selinux_wrapper() {
    local ENFORCE=0
    [ "$(getenforce)" = "enforcing" ] && ENFORCE=1
    trap "su root -c 'setenforce $ENFORCE'; trap INT TERM QUIT" INT TERM QUIT
    su root -c "setenforce 0; ${@:?Nothing to do...}"
}

# Key events
keyevent() {
  if [ "$USER" = "shell" ]; then
    for K; do input keyevent "$K"; done
  else
    su root -c "for K in $@; do input keyevent \"\$K\"; done"; fi
}

# Adb
adb_start() { su root -c 'setprop persist.service.adb.enable 1; start adbd'; }
adb_stop() { su root -c 'setprop persist.service.adb.enable 0; stop adbd'; }
adb_toggle() {
    if [ "$(getprop persist.service.adb.enable)" = "0" ]; then
        echo "Enable adb"
        adb_start
    else
        echo "Disable adb"
        adb_stop
    fi
}

# Lock/unlock screen
unlock() { keyevent 82; }
lock() { keyevent 6 26; }

# Open default browser
browser() { keyevent 23; }

# Volume
volp() { keyevent 24; }
voln() { keyevent 25; }

# Go to home screen
home() { keyevent 3; }

# Screenshot
screenshot() { screenshot "${1:-/sdcard/screenshot-$(date +%s).png}"; }

# Another screenshot capture command
#screencap [-hp] [-d display-id] [FILENAME]
# -h: this message
# -p: save the file as a png.
# -d: specify the display id to capture, default 0

# Clock app
clock_start() { am start com.google.android.deskclock; }
clock_stop() { am force-stop com.google.android.deskclock; }

# Wifi
wifi_mgr() { am start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings; }
wifi_status() { am start -n com.android.settings/.wifi.WifiStatusTest; }
wifi_on() { su root -c 'svc wifi enable'; }
wifi_off() { su root -c 'svc wifi disable'; }
wifi_state() { ip addr show dev "${1:-wlan0}" 2>/dev/null | grep "state UP" >/dev/null; echo $?; }

# Bluetooth
bt_enable() { su root -- svc bluetooth enable; }
bt_disable() { su root -- svc bluetooth disable; }

# Usb
usb_get_fct() { su root -- svc usb getFunction; }
usb_set_fct() { su root -- svc usb setFunction; }

# Nfc
nfc_enable() { su root -- svc nfc enable; }
nfc_disable() { su root -- svc nfc disable; }

# Power
pwr_stayon() { su root -- svc power stayon; }
pwr_shutdown() { su root -- svc power shutdown; }
pwr_halt() { su root -- svc power shutdown; }
pwr_reboot() { su root -- svc power reboot; }

# Mobile Data
data_on() { su root -c 'svc data enable'; }
data_off() { su root -c 'svc data disable'; }
data() { [ "$1" = "1" -o "$1" = "true" ] && data_on || data_off; }

# Mobile Data eco
data_eco_off() { selinux_wrapper 'cmd netpolicy set restrict-background false'; }
data_eco_on() { selinux_wrapper 'cmd netpolicy set restrict-background true'; }
data_eco() { [ "$1" = "1" -o "$1" = "true" ] && data_eco_on || data_eco_off; }

# Power-save mode (need seLinux off)
# https://stackoverflow.com/questions/28234502/programmatically-enable-disable-battery-saver-mode
pwr_sav_enable() { selinux_wrapper settings put global low_power 1; }
pwr_sav_disable() { selinux_wrapper settings put global low_power 0; }
pwr_sav_get_lvl() { selinux_wrapper settings get global low_power_trigger_level; }
pwr_sav_set_lvl() { selinux_wrapper settings put global low_power_trigger_level; }

# Airplane mode
# https://stackoverflow.com/questions/10506591/turning-airplane-mode-on-via-adb/40271379
airplane_enable() { selinux_wrapper "settings put global airplane_mode_on 1 ; am broadcast -a android.intent.action.AIRPLANE_MODE"; }
airplane_disable() { selinux_wrapper "settings put global airplane_mode_on 0 ; am broadcast -a android.intent.action.AIRPLANE_MODE"; }
airplane_status() { selinux_wrapper settings get global airplane_mode_on; }

# Localisation (deprecated in recent Android10)
# https://forum.xda-developers.com/android/help/activate-disable-gps-adb-shell-t3307417
loc_disable() { selinux_wrapper "settings put secure location_providers_allowed -gps ; settings put secure location_providers_allowed -network"; }
loc_enable_gps() { selinux_wrapper settings put secure location_providers_allowed +gps; }
loc_enable_network() { selinux_wrapper settings put secure location_providers_allowed +network; }
loc_enable_full() { selinux_wrapper "settings put secure location_providers_allowed +gps ; settings put secure location_providers_allowed +network"; }
loc_status() { selinux_wrapper settings get secure location_providers_allowed; }

# Localisation (android 10)
# https://android.stackexchange.com/questions/40147/is-it-possible-to-enable-location-services-via-shell
#LOCATION_MODE_OFF=0
#LOCATION_MODE_POWER_SAVE=1
#LOCATION_MODE_GPS=2
#LOCATION_MODE_HIGH_ACCURACY=3
loc_disable_2() { selinux_wrapper settings put secure location_mode 0; }
loc_enable_gps_2() { selinux_wrapper settings put secure location_mode 2; }
loc_enable_network_2() { selinux_wrapper settings put secure location_mode 1; }
loc_enable_full_2() { selinux_wrapper settings put secure location_mode 3; }
loc_status() { selinux_wrapper settings settings get secure location_mode; }

# Permissions
# Ex: su root -- cmd appops set <pkg> RUN_IN_BACKGROUND [ignore|allow]
perm_set() { su root -- cmd appops set "${1:?No package specified...}" "${2:?No permission specified...}" "${3:?No value specified...}"; }
perm_get() { su root -- cmd appops get "${1:?No package specified...}" "${2:?No permission specified...}"; }
perm_add() { pm grant "$@"; }
perm_rm() { pm revoke "$@"; }

# Get logcat
logcat() { su root -c "logcat "$@""; }

# Apps
app_start(){ am start -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
app_restart(){ am start -S -n "${1:?No package name specified...}/${2:-.MainActivity}"; }
app_stop(){ am force-stop "${1:?No package name specified...}"; }

# Packages
pkg_ls() { pm list packages -f | cut -f 2 -d "=" | sort; }
pkg_start() {
    local PACKAGE="${1:?No package name specified...}"
    local ACTIVITY="${2:-.MainActivity}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am start -n "{}/$ACTIVITY"
}
pkg_stop() {
    local PACKAGE="${1:?No package name specified...}"
    pm list packages -f | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 am force-stop -n "{}"
}

# Setup apps
pkg_install() { for P; do su root -c "sudo pm install -r $P"; done; }
pkg_uninstall() { for P; do pm uninstall -k "$P"; done; }
pkg_uninstall_root() { for P; do pm uninstall -k --user 0 "$P"; done; }

# Services
svc_start(){ am startservice "${1:?No package name specified...}/${2:?No service name specified...}" ${3:+--user "$3"}; }
svc_stop(){ am stopservice "${1:?No package name specified...}" ${3:+--user "$3"}; }

# Clipboard
clipboard_status() { cmd appops query-op --user 0 READ_CLIPBOARD allow; }
clipboard_disable() { for PKG; do cmd appops set "$PKG" READ_CLIPBOARD ignore; done; }
clipboard_enable() { for PKG; do cmd appops set "$PKG" READ_CLIPBOARD allow; done; }

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
alias spp='setprop'
alias gpp='getprop'
gppg() { getprop ${@:+| grep $@}; }


########################################
########################################
# Last commands in file
# Execute function from command line
[ -n "$1" ] && "$@" || true
