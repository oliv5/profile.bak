#!/bin/sh

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
  local RESOLUTION="${1:?No resolution specified, like 1280x1024}"
  local ARGS="$@"
  xrandr -s "$RESOLUTION" "$ARGS"
}

# Enable display
xrandr_en() {
  #See options like --dryrun, --mode 1024x768
  xrandr --output "${1:?No display specified}" --auto "$(shell_ltrim 1 "$@")"
}

# Disable display
xrandr_dis() {
  xrandr --output "${1:?No display specified}" --off "$(shell_ltrim 1 "$@")"
}
