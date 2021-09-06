#!/bin/sh

# NAME: set-hyper-threading
# DESC: Turn Hyper threading off or on.
# DATE: Aug. 5, 2017.
# NOTE: https://askubuntu.com/questions/942728/disable-hyper-threading-in-ubuntu/942843#942843
# PARM: $1 = "0" turn off hyper threading, "1" turn it on.

echo "Devices"
grep "" /sys/devices/system/cpu/cpu*/topology/core_id
echo

grep -q '^flags.*[[:space:]]ht[[:space:]]' /proc/cpuinfo && \
    echo "Hyper-threading is supported" && echo

grep -E 'model|stepping' /proc/cpuinfo | sort -u
echo

for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
    CORE_ID="${CPU##*cpu}"
    SIBLING_ID=""
    ENABLED=""

    if [ -f "${CPU}/topology/thread_siblings_list" ]; then
        # Real core ID is the first number in thread_siblings_list
        SIBLING_ID="$(cut -d',' -f1 ${CPU}/topology/thread_siblings_list)"
        # If CORE_ID != SIBLING_ID; then this is a virtual core
        if [ -f "${CPU}/online" ] && [ "$CORE_ID" != "$SIBLING_ID" ]; then
            ENABLED="$(cat ${CPU}/online)"
        fi
    fi

    if [ $# -ge 1 ]; then
        if [ -n "$ENABLED" ]; then
            if [ "$1" = "0" -o "$1" = "1" ]; then
                STATE="$1"
            else
                STATE="$ENABLED"
                STATE="$((1-STATE))"
            fi
            sudo sh -c "echo -n '$STATE' > '${CPU}/online'"
            echo "Switch ${CPU}/online to $STATE"
        fi
    else
        echo "Linux device: $CPU"
        echo "Core ID:      $CORE_ID"
        echo "Real core ID: $SIBLING_ID"
        if [ -n "$ENABLED" ]; then
            echo "HT enabled:   $ENABLED"
        else
            echo "HT enabled:   N/A"
        fi        
    fi
done
