#!/bin/sh
# Useful actions to execute:
# adb shell svc wifi enable
# adb shell svc wifi disable

main() {
    local LOCATION_FILE="${1:-.locations}"
    # Check prerequisites
    if ! command -v bc >/dev/null 2>&1; then
        echo >&2 "[error] Cannot find bc. Abort..."
        exit 1
    fi
    if ! command -v gps.sh >/dev/null 2>&1; then
        echo >&2 "[error] Cannot find gps.sh. Abort..."
        exit 1
    fi
    
    # Get current location
    local HERE=$(${ANDROID_ROOT:+.} gps.sh location)
    
    # Read the location file and execute appropriate actions
    grep -v "^\s*#" "$LOCATION_FILE" | 
        while IFS=$' ' read LOC OP DIST ACTION; do
            if [ -n "$ACTION" ]; then
                DISTANCE=$(${ANDROID_ROOT:+.} gps.sh dist "$HERE" "$LOC" 0)
                if expr $(($DISTANCE)) $OP $(($DIST)) >/dev/null; then
                    eval "$ACTION"
                fi
            fi
        done
}

# Just do it
main "$@"
