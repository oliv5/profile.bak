#!/bin/sh
# https://thangamaniarun.wordpress.com/2013/04/19/useful-android-adb-commands-over-usbwi-fi/

# Execute command through adb wrapper in /sdcard/.adbrc
adb_exec() {
    adb shell /sdcard/.adbrc "$@"
}

# Connect adb over wi-fi
adb_wifi() {
    adb shell "setprop service.adb.tcp.port ${2:-5555} && stop adbd && start adbd"
    adb connect "${1:?No IP address specified...}:${2:-5555}"
    adb devices
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
