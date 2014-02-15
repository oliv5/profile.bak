#!/bin/bash

# Get screen resolution
function xrandr-getres() {
  xrandr | grep \* | cut -d' ' -f4
}

# Set screen resolution
function xrandr-setres() {
  xrandr -s ${1:?Please give screen resolution, like 1280x1024} ${@:2}
}
