#!/bin/sh
# See http://www.movable-type.co.uk/scripts/latlong.html
#adb shell svc wifi enable
#adb shell svc wifi enable
#adb shell dumpsys location

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
    [ $# -ne 3 ] && echo >&2 "Wrong number of parameters ($#/3)" && return 0
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
    [ $# -ne 4 ] && echo >&2 "Wrong number of coordonnates ($#/4)" && return 0
    # Get parameters
    LAT1="$1"; LAT2="$2"; LONG1="$3"; LONG2="$4"
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
    D=$(math "$R * sqrt($X*$X + $Y*$Y)")
    # Return
    echo $D
}

# Test distance computation method
dist_pythagora_test() {
    local LOCATION1="48,910326,2,234379"
    local LOCATION2="48,909986,2,233445"
    local DISTANCE="78.02910620730578864000"
    local LAT1=0; local LONG1=0
    local LAT2=0; local LONG2=0
    gm_coordonates "$LOCATION1" LAT1 LONG1
    gm_coordonates "$LOCATION2" LAT2 LONG2
    [ "$(dist_pythagora "$LAT1" "$LAT2" "$LONG1" "$LONG2")" = "$DISTANCE" ] &&
	echo "dist_pythagora: OK" || echo "dist_pythagora: NOK"
}

# Main processing
dist_pythagora_test

# Get GPS locations
LOCATION1="48,910326,2,234379"
LOCATION2="48,909986,2,233445"

# Extract coordonates
#LAT1=0; LAT2=0; LONG1=0; LONG2=0
#eval $(echo $LOCATION1 | sed -r 's/([^,]*),([^,]*),([^,]*),([^,]*)/LAT1=\1.\2 ; LONG1=\3.\4/')
#eval $(echo $LOCATION2 | sed -r 's/([^,]*),([^,]*),([^,]*),([^,]*)/LAT2=\1.\2 ; LONG2=\3.\4/')
gm_coordonates "$LOCATION1" LAT1 LONG1
gm_coordonates "$LOCATION2" LAT2 LONG2

# Compute distance
dist_pythagora "$LAT1" "$LAT2" "$LONG1" "$LONG2"
