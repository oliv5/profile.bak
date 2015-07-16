#!/bin/sh
# Script dependencies
RC_DEPENDENCIES="${RC_DEPENDENCIES:+$RC_DEPENDENCIES }shell fct"

# List devices
xrandr_connected() {
  xrandr -q | awk '/ connected/{print $1}'
}
xrandr_disconnected() {
  xrandr -q | awk '/disconnected/{print $1}'
}
xrandr_on() {
  xrandr -q | awk '/ connected/{name=$1} /*/{print name}'
}
xrandr_off() {
  xrandr -q | awk '/ connected/{name=$1} /*/{name=""} END{print name}'
}

# Get screen resolution
xrandr_getres() {
  xrandr --current | grep \* | cut -d' ' -f4
}

# Set screen resolution
xrandr_setres() {
  local ARG1="$1"; shift $(min 1 $#)
  xrandr -s "${ARG1:?No resolution specified, like 1280x1024}" "$@"
}

# Enable display
xrandr_en() {
  #See options like --dryrun, --mode 1024x768
  local ARG1="$1"; shift $(min 1 $#)
  xrandr --output "${ARG1:?No display specified}" --auto "$@"
}

# Disable display
xrandr_dis() {
  local ARG1="$1"; shift $(min 1 $#)
  xrandr --output "${ARG1:?No display specified}" --off "$@"
}
