#!/bin/sh
# See http://www.movable-type.co.uk/scripts/latlong.html
#adb shell svc wifi enable
#adb shell svc wifi enable
#adb shell dumpsys location

# Run in a subshell because of the exit command
(
    # Check prerequisites
    if ! command -v bc >/dev/null 2>&1; then
        echo >&2 "[error] Cannot find bc. Abort..."
        exit 1
    fi

    # Math fct
    math() {
        echo "$@" | bc -l
    }

    # Convert degrees to radians
    radians() {
        echo "pi=4*a(1); $1 * pi / 180" | bc -l
    }

    # (android only) Get current google map GPS coordonates (format "LAT,LAT,LONG,LONG")
    gm_location() {
        [ -z "$ANDROID_ROOT" ] && echo >&2 "Not on android, cannot get current location." && echo "0,0,0,0" && return 1
        dumpsys location | awk '/passive: Location/ {print $3}' | head -n 1
    }

    # Convert google map GPS coordonates to latitude, longitude
    gm_coordonates() {
        [ $# -ne 3 ] && echo >&2 "Wrong number of parameters ($#/3)" && return 1
        eval "$(echo ${1:-0,0,0,0} | sed -r "s/([^,]*),([^,]*),([^,]*),([^,]*)/$2=\1.\2 ; $3=\3.\4/")"
    }

    # Distance computation
    #Equirectangular approximation
    #If performance is an issue and accuracy less important, for small distances Pythagoras’ theorem can be used on an equirectangular projection:*
    #Formula
    #x = Δλ ⋅ cos φm
    #y = Δφ
    #d = R ⋅ √x² + y²
    #JavaScript:	
    #var R = 6371000; // metres
    #var φ1 = lat1.toRadians();
    #var φ2 = lat2.toRadians();
    #var Δφ = (lat2-lat1).toRadians();
    #var Δλ = (lon2-lon1).toRadians();
    #var x = (λ2-λ1) * Math.cos((φ1+φ2)/2);
    #var y = (φ2-φ1);
    #var d = Math.sqrt(x*x + y*y) * R;
    dist_pythagora() {
        [ $# -ne 4 ] && echo >&2 "Wrong number of coordonnates ($#/4)" && return 1
        math "
            # Radian function
            define radians(degrees) {
                auto pi; pi = 4 * a(1)
                return (degrees * pi / 180)
            }
            # Get parameters
            lat1=$1; long1=$2; lat2=$3; long2=$4
            # Earth radius
            r = 6371000
            # Latitude
            phy1 = radians(lat1)
            phy2 = radians(lat2)
            # Deltas latitude and longitude
            delta1 = radians(lat2 - lat1)
            delta2 = radians(long2 - long1)
            # Coordonates and distance
            x = delta2 * c((phy1 + phy2) / 2)
            y = phy2 - phy1
            # Distance (2 frac. digits)
            scale = 2
            r * sqrt(x*x + y*y) / 1
        "
    }
    dist_pythagora_shell() {
        [ $# -ne 4 ] && echo >&2 "Wrong number of coordonnates ($#/4)" && return 1
        # Get parameters
        LAT1="$1"; LONG1="$2"; LAT2="$3"; LONG2="$4"
        # Earth radius
        R=6371000
        # Latitude
        PHY1=$(radians $LAT1)
        PHY2=$(radians $LAT2)
        # Deltas latitude and longitude
        DELTA1=$(radians $(math $LAT2 - $LAT1))
        DELTA2=$(radians $(math $LONG2 - $LONG1))
        # Coordonates and distance
        X=$(math "$DELTA2 * c(($PHY1 + $PHY2) / 2)")
        Y=$(math "$PHY2 - $PHY1")
        math "scale=2; $R * sqrt($X*$X + $Y*$Y) / 1"
    }

    # Test distance computation method
    dist_pythagora_test() {
        local LOCATION1="48,910326,2,234379"
        local LOCATION2="48,909986,2,233445"
        local DISTANCE="78.02"  #"78.02910620730578864000"
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        gm_coordonates "$LOCATION1" LAT1 LONG1
        gm_coordonates "$LOCATION2" LAT2 LONG2
        RES=$(dist_pythagora "$LAT1" "$LONG1" "$LAT2" "$LONG2")
        echo -n "[TEST] dist_pythagora: res=$RES "
        [ "$RES" = "$DISTANCE" ] && echo "[OK]" || echo "[NOK]"
    }

    # Distance computation
    dist() {
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        gm_coordonates "${1:-$(gm_location)}" LAT1 LONG1
        gm_coordonates "${2:-$(gm_location)}" LAT2 LONG2
        dist_pythagora "$LAT1" "$LONG1" "$LAT2" "$LONG2"
    }

    ########################################
    ########################################
    # Last commands in file
    # Execute function from command line
    [ $# -gt 0 -a ! -z "$1" ] && "$@" || true

)
