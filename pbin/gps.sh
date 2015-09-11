#!/bin/sh
# See http://www.movable-type.co.uk/scripts/latlong.html

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

    # (android only) Get current GPS coordonates (format "LAT.LAT,LONG.LONG")
    android_location() {
        [ -z "$ANDROID_ROOT" ] && echo >&2 "Not on android, cannot get current location." && echo "0.0 0.0" && return 1
        dumpsys location | awk '/passive: Location/ {print $3}' | sed -e 's/,/./1 ; s/,/./2 ; q'
    }

    # Get GPS location estimate from website
    web_location() {
        curl -s ipinfo.io | awk '/"loc":/{print substr($2,2,length($2)-3)}'
    }
    
    # Get coordonates in variables
    coordonates() {
        [ $# -ne 3 ] && echo >&2 "Wrong number of parameters ($#/3)" && return 1
        local V1="$2"; local V2="$3"
        IFS=','; set -- $1
        eval "$V1=$1; $V2=$2"
        eval "[ -z \"$1\" -o -z \"$2\" ] && echo >&2 'Bad coordonates, conversion error.' && return 1"
    }

    # Location retrieve function
    location() {
        if [ -n "$ANDROID_ROOT" ]; then 
            android_location
        else 
            web_location
        fi
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
        [ $# -ne 4 -a $# -ne 5 ] && echo >&2 "Wrong number of coordonnates ($#/[4-5])" && return 1
        : ${1:?Bad coordonate LAT1} ${2:?Bad coordonate LONG1}
        : ${3:?Bad coordonate LAT2} ${4:?Bad coordonate LONG2}
        : ${SCALE:=${5:-2}}
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
            scale = $SCALE
            r * sqrt(x*x + y*y) / 1
        "
    }
    dist_pythagora_shell() {
        [ $# -ne 4 -a $# -ne 5 ] && echo >&2 "Wrong number of coordonnates ($#/[4-5])" && return 1
        : ${1:?Bad coordonate LAT1} ${2:?Bad coordonate LONG1}
        : ${3:?Bad coordonate LAT2} ${4:?Bad coordonate LONG2}
        : ${SCALE:=${5:-2}}
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
        math "scale=$SCALE; $R * sqrt($X*$X + $Y*$Y) / 1"
    }

    # Test distance computation method
    dist_pythagora_test() {
        local LOCATION1="48.910326,2.234379"
        local LOCATION2="48.909986,2.233445"
        local DISTANCE="78.02"  #"78.02910620730578864000"
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        coordonates "$LOCATION1" LAT1 LONG1
        coordonates "$LOCATION2" LAT2 LONG2
        RES=$(dist_pythagora "$LAT1" "$LONG1" "$LAT2" "$LONG2")
        echo -n "[TEST] dist_pythagora: res=$RES "
        [ "$RES" = "$DISTANCE" ] && echo "[OK]" || echo "[NOK]"
    }

    # Distance computation
    dist() {
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        coordonates "${1:-$(location)}" LAT1 LONG1
        coordonates "${2:-$(location)}" LAT2 LONG2
        dist_pythagora "$LAT1" "$LONG1" "$LAT2" "$LONG2" $3
    } 

    ########################################
    ########################################
    # Last commands in file
    # Execute function from command line
    [ $# -gt 0 -a ! -z "$1" ] && "$@" || true
)
