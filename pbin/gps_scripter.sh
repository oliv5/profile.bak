#!/bin/sh
# Useful actions to execute:
# adb shell svc wifi enable
# adb shell svc wifi disable
(
    # Variables
    LOCATION_FILE="${1:-.locations}"
    
    # Check prerequisites
    if [ -z "$ANDROID_ROOT" ] && ! command -v gps.sh >/dev/null 2>&1; then
        echo >&2 "[error] Cannot find gps.sh. Abort..."
        exit 1
    fi
    
    # Get current location
    HERE=$(${ANDROID_ROOT:+.} gps.sh location)
    echo "[gps] Current location: $HERE"
    
    # Read the location file and execute appropriate actions
    grep -v "^\s*#" "$LOCATION_FILE" | 
        while IFS=$' ' read LOC OP DIST ACTION; do
            if [ -n "$ACTION" ]; then
                DISTANCE=$(${ANDROID_ROOT:+.} gps.sh dist "$HERE" "$LOC" 0)
                echo "[gps] Process rule: dist($HERE, $LOC) = $DISTANCE $OP $DIST then execute '$ACTION'"
                if expr ${DISTANCE:-0} $OP ${DIST:-0} >/dev/null; then
                    echo "[gps] Execute: $ACTION"
                    eval "$ACTION"
                fi
            fi
        done
) > "${2:-/dev/stdout}"
