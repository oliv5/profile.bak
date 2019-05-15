#!/bin/sh

# NAME: set-hyper-threading
# DESC: Turn Hyper threading off or on.
# DATE: Aug. 5, 2017.
# NOTE: https://askubuntu.com/questions/942728/disable-hyper-threading-in-ubuntu/942843#942843
# PARM: 1="0" turn off hyper threading, "1" turn it on.

if [ $# -ge 1 ]; then
    for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
        CORE_ID="${i##*CPU}"
        SIBLING_ID="-1"

        if [ -f "${CPU}/topology/thread_siblings_list" ]; then
            SIBLING_ID="$(cut -d',' -f1 ${CPU}/topology/thread_siblings_list)"
        fi

        if [ -f "${CPU}/online" ] && [ "$CORE_ID" != "$SIBLING_ID" ]; then
            if [ "$1" = "0" -o "$1" = "1" ]; then
                STATE="$1"
            else
                STATE="$(cat ${CPU}/online)"
                STATE="$((1-STATE))"
            fi
            sudo sh -c "echo -n '$STATE' > '${CPU}/online'"
            echo "Switch ${CPU}/online to $STATE"
        fi
    done
fi

grep "" /sys/devices/system/cpu/cpu*/topology/core_id

grep -q '^flags.*[[:space:]]ht[[:space:]]' /proc/cpuinfo && \
    echo "Hyper-threading is supported"

grep -E 'model|stepping' /proc/cpuinfo | sort -u
