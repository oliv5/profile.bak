#!/bin/sh
# https://thangamaniarun.wordpress.com/2013/04/19/useful-android-adb-commands-over-usbwi-fi/

# Connect adb over wi-fi
adb_wifi() {
    adb shell "setprop service.adb.tcp.port ${2:-5555} && stop adbd && start adbd"
    adb connect "${1:?No IP address specified...}:${2:-5555}"
    adb devices
}

# Unlock your Android screen
adb_unlock() {
    adb shell input keyevent 82
}

# Lock your Android screen
adb_lock() {
    adb shell input keyevent 6
    adb shell input keyevent 26
}

# Open default browser
adb_browser() {
    adb shell input keyevent 23
}

# Keep your android phone volume up(+)
adb_volp() {
    adb shell input keyevent 24
}

# Keep your android phone volume down(-)
adb_voln() {
    adb shell input keyevent 25
}

# Go to your Android Home screen
adb_home() {
    adb shell input keyevent 3
}

# Take Screenshot from adb
adb_screenshot() {
    adb shell screenshot /sdcard/test.png
}

# Another Screen capture command
#screencap [-hp] [-d display-id] [FILENAME]
# -h: this message
# -p: save the file as a png.
# -d: specify the display id to capture, default 0

# Start clock app
adb_clock_start() {
    adb shell am start com.google.android.deskclock
}

# Stop clock app
adb_clock_stop() {
    adb shell am force-stop com.google.android.deskclock
}

# Send termux cmd
adb_termux_cmd() {
    adb shell am start -n com.termux/.app.TermuxActivity &&
    adb shell input text "$@" &&
    adb shell input keyevent 113 &&
    adb shell input keyevent 66
}

# Start wifi settings manager
adb_wifi_mgr() {
    adb shell am start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings
}

# Testing wifi status – Thanks Saimadhu
adb_wifi_status() {
    adb shell am start -n com.android.settings/.wifi.WifiStatusTest
}

# Wifi on (root only)
adb_wifi_on() {
    adb shell svc wifi enable
}

# Wifi off (root only)
adb_wifi_off() {
    adb shell svc wifi disable
}

# Mobile Data on (root only)
adb_data_on() {
    adb shell svc data enable
}

# Mobile Data off (root only)
adb_data_off() {
    adb shell svc data disable
}

# Mobile Data eco off (root only)
adb_data_eco_off() {
    adb shell cmd netpolicy set restrict-background false
}

# Mobile Data echo on (root only)
adb_data_eco_off() {
    adb shell cmd netpolicy set restrict-background true
}

# Get logcat (root only)
adb_logcat() {
    adb shell logcat
}

# List packages
adb_ls_packages() {
    adb shell "pm list packages -f" | cut -f 2 -d "=" | sort
}

# Start/stop an app from its package partial name
adb_start_pkg() {
    local PACKAGE="${1:?No package name specified...}"
    local ACTIVITY="${2:-.MainActivity}"
    adb shell "pm list packages -f" | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 adb shell am start -n "{}/$ACTIVITY"
}
adb_stop_pkg() {
    local PACKAGE="${1:?No package name specified...}"
    adb shell "pm list packages -f" | awk -F= "/${PACKAGE}/ {print \$2}" | xargs -I {} -r -n1 adb shell am force-stop -n "{}"
}

# Android backup (files only, Android4.0+)
alias adb_backup_userapp='adb_backup "" -all -apk -oob -no-system'
alias adb_backup_systemapp='adb_backup "" -all -apk -oob -system'
alias adb_backup_shared='adb_backup "" -shared'
alias adb_backup_all='adb_backup "" -apk -oob -all -system -shared'
adb_backup() {
    local DST="${1:-./adb_backup.$(date +%Y%m%d-%H%M).dat}"
    eval "${1:+shift}"
    adb backup "$@" -f "$DST" &&
      [ -s "$DST" ] &&
      7z a "${DST}.7z" "$DST" &&
      rm "$DST"
}

# Nandroid backup from adb
# http://forum.xda-developers.com/showthread.php?t=1818321
# Whole memory: /dev/block/mmcblk0
# Sub-partitions: /dev/block/platform/msm_sdcc.1/by-name/ ... (boot;recovery;system;userdata;...)
adb_backup_nandroid() {
    local DEV="${1:-/dev/block/mmcblk0}"
    local DST="${2:-./nandroid_backup_$(date '+%Y%m%d_%H%M%S')_$(basename "$DEV")}"
    local PORT="${3:-5555}"
    # Check prerequisites
    type adb >/dev/null
    # First shell
    (   set +e
        adb forward "tcp:$PORT" "tcp:$PORT" &&
        adb shell su root /system/xbin/busybox nc -l -p "$PORT" -e /system/xbin/busybox dd if="$DEV"
    ) &
    # Let the UE start nc
    sleep 2s
    # Second shell
    (   set -e
        adb forward "tcp:$PORT" "tcp:$PORT" &&
        nc 127.0.0.1 "$PORT" | pv -i 0.5 > "${DST}.raw" &&
        [ -s "${DST}.raw" ] &&
        7z a "${DST}.raw.7z" "${DST}.raw" 2>/dev/null &&
        rm "${DST}.raw"
    )
}
# Restore ?
# https://forum.xda-developers.com/showthread.php?p=58350784#post58350784
# Beware of bootloader / recovery partitions
# pc: gzip -c mmcblk0.raw | nc -l -p 5555
# phone: /sbin/busybox nc 127.0.0.1 5555 | gunzip -c | dd bs=4096 of=/dev/block/mmcblk0

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#adb}" != "$1" ] && "$@" || true
