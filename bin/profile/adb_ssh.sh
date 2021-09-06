#!/bin/sh
#https://github.com/termux/termux-app/issues/924
if [ -n "$ADB_IP" ]; then
    adb connect "$ADB_IP" "${ADB_PORT:-5555}"
fi
adb forward tcp:18443 tcp:8443
ssh -p 18443 ${ADB_USER:+${ADB_USER}@}127.0.0.1 -- "$@"
adb forward --remove tcp:18443
