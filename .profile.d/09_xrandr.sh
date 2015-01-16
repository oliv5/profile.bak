#!/bin/bash

# List devices
function xrandr-connected() {
  xrandr -q | awk '/ connected/{print $1}'
}
function xrandr-disconnected() {
  xrandr -q | awk '/disconnected/{print $1}'
}
function xrandr-on() {
  xrandr -q | awk '/ connected/{name=$1} /*/{print name}'
}
function xrandr-off() {
  xrandr -q | awk '/ connected/{name=$1} /*/{name=""} END{print name}'
}

# Get screen resolution
function xrandr-getres() {
  xrandr --current | grep \* | cut -d' ' -f4
}

# Set screen resolution
function xrandr-setres() {
  xrandr -s ${1:?No resolution specified, like 1280x1024} ${@:2}
}

# Enable display
function xrandr-en() {
  #See options like --dryrun, --mode 1024x768
  xrandr --output "${1:?No display specified}" --auto ${@:2}
}

# Disable display
function xrandr-dis() {
  xrandr --output "${1:?No display specified}" --off ${@:2}
}
