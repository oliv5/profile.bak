#!/bin/bash

# Get screen resolution
function xrandr-getres() {
  xrandr --current | grep \* | cut -d' ' -f4
}

# Set screen resolution
function xrandr-setres() {
  xrandr -s ${1:?No resolution specified, like 1280x1024} ${@:2}
}

# Enable display
function xrandr-on() {
  #See options like --dryrun, --mode 1024x768
  xrandr --output "${1:?No display specified}" --auto ${@:2}
}

# Disable display
function xrandr-off() {
  xrandr --output "${1:?No display specified}" --off ${@:2}
}
