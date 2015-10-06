#!/bin/sh
# See http://www.movable-type.co.uk/scripts/latlong.html

# Run in a subshell because of the exit command
(
    # Math fct
    bc_calc() {
        echo "$@" | bc -l
    }

    # Convert degrees to radians
    bc_radians() {
        # Pi = 4 * atan(1)
        bc_calc "pi=4*a(1); $1 * pi / 180"
    }

    # Math fct
    awk_calc() {
        #echo | eval awk -v CONVFMT=%.${AWK_PRECISION:-17}g "'{\$1=$@;}{print}'"
        echo | eval awk "'{printf \"%."${AWK_PRECISION:-17}"f\n\",$@}'"
    }

     # Convert degrees to radians
    awk_radians() {
        awk_calc "$1 * 4 * atan2(1,1) / 180"
    }

    # (android only) Get current GPS coordonates (format "LAT.LAT,LONG.LONG")
    android_location() {
        [ -z "$ANDROID_ROOT" ] && echo >&2 "Not on android, cannot get current location." && echo "0.0 0.0" && return 1
        su root -- dumpsys location | awk '/(network|passive): Location/ {print $3}' | sed -e 's/,/./1 ; s/,/./2 ; q'
    }

    # Get GPS location estimate from website
    web_location() {
        curl -s ipinfo.io | awk '/"loc":/{print substr($2,2,length($2)-3)}'
    }

    # Location retrieve function
    location() {
        if [ -n "$ANDROID_ROOT" ]; then 
            local LOCATION="$(android_location)"
        else 
            local LOCATION="$(web_location)"
        fi
        echo "${LOCATION:-0.0,0.0}"
    }
    
    # Get coordonates in variables
    coordonates() {
        [ $# -ne 3 ] && echo >&2 "Wrong number of parameters ($#/3)" && return 1
        local V1="$2"; local V2="$3"
        if [ "$1" = "HERE" ] || [ "$1" = "here" ]; then
            local IFS=','; set -- $(location)
        else
            local IFS=','; set -- $1
        fi
        eval "$V1=$1; $V2=$2"
        eval "[ -z \"$1\" -o -z \"$2\" ] && echo >&2 'Bad coordonates format [lat,long]' && return 1"
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
        # Get parameters
        local PRECISION="${5:-2}"
        # Compute
        bc_calc "
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
            scale = $PRECISION
            r * sqrt(x*x + y*y) / 1
        "
    }
    dist_pythagora_awk() {
        [ $# -ne 4 -a $# -ne 5 ] && echo >&2 "Wrong number of coordonnates ($#/[4-5])" && return 1
        : ${1:?Bad coordonate LAT1} ${2:?Bad coordonate LONG1}
        : ${3:?Bad coordonate LAT2} ${4:?Bad coordonate LONG2}
        # Get parameters
        local LAT1="$1"; local LONG1="$2"; local LAT2="$3"; local LONG2="$4"
        local PRECISION="${5:-2}"
        # Earth radius
        local R=6371000
        # Latitude
        local PHY1=$(awk_radians $LAT1)
        local PHY2=$(awk_radians $LAT2)
        # Deltas latitude and longitude
        local DELTA1=$(awk_radians $(awk_calc $LAT2 - $LAT1))
        local DELTA2=$(awk_radians $(awk_calc $LONG2 - $LONG1))
        # Coordonates and distance
        local X=$(awk_calc "$DELTA2 * cos(($PHY1 + $PHY2) / 2)")
        local Y=$(awk_calc "$PHY2 - $PHY1")
        AWK_PRECISION=$PRECISION awk_calc "$R * sqrt($X*$X + $Y*$Y) / 1"
    }

    # Test distance computation method
    dist_test() {
        local METHOD="${1:-dist_pythagora_test}"
        local LOCATION1="48.910326,2.234379"
        local LOCATION2="48.909986,2.233445"
        local DISTANCE="${2:-78.02910620730578864000}"
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        coordonates "$LOCATION1" LAT1 LONG1
        coordonates "$LOCATION2" LAT2 LONG2
        eval "RES=$($METHOD "$LAT1" "$LONG1" "$LAT2" "$LONG2")"
        echo -n "[TEST] $METHOD: res=$RES exp=$DISTANCE "
        [ "$RES" = "$DISTANCE" ] && echo "[OK]" || echo "[NOK]"
    }

    # Test distance computation methods
    dist_pythagora_test() {
        dist_test dist_pythagora 78.02
    }
    dist_pythagora_awk_test() {
        dist_test dist_pythagora_awk 78.2336
    }

    # Distance computation
    dist() {
        command -v bc >/dev/null && 
            local METHOD="dist_pythagora" || 
            local METHOD="dist_pythagora_awk"
        local LAT1=0; local LONG1=0
        local LAT2=0; local LONG2=0
        coordonates "${1:-$(location)}" LAT1 LONG1
        coordonates "${2:-$(location)}" LAT2 LONG2
        $METHOD "$LAT1" "$LONG1" "$LAT2" "$LONG2" $3
    } 

    ########################################
    ########################################
    # Last commands in file
    # Execute function from command line
    [ $# -gt 0 -a ! -z "$1" ] && "$@" || true
)
