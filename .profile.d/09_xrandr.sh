#!/bin/sh

# List devices
xrandr-connected() {
  xrandr -q | awk '/ connected/{print $1}'
}
xrandr-disconnected() {
  xrandr -q | awk '/disconnected/{print $1}'
}
xrandr-on() {
  xrandr -q | awk '/ connected/{name=$1} /*/{print name}'
}
xrandr-off() {
  xrandr -q | awk '/ connected/{name=$1} /*/{name=""} END{print name}'
}

# Get screen resolution
xrandr-getres() {
  xrandr --current | grep \* | cut -d' ' -f4
}

# Set screen resolution
xrandr-setres() {
  xrandr -s ${1:?No resolution specified, like 1280x1024} ${@:2}
}

# Enable display
xrandr-en() {
  #See options like --dryrun, --mode 1024x768
  xrandr --output "${1:?No display specified}" --auto ${@:2}
}

# Disable display
xrandr-dis() {
  xrandr --output "${1:?No display specified}" --off ${@:2}
}
