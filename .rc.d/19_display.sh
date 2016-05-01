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
  local ARG1="$1"; shift $(min 1 $#)
  xrandr -s "${ARG1:-0}" "$@"
}
alias xrandr_refresh='xrandr_setres 0'
alias xrandr_1280='xrandr_setres 1280x1024'
alias xrandr_1024='xrandr_setres 1024x768'
alias xrandr_800='xrandr_setres 800x600'
alias xrandr_640='xrandr_setres 640x480'

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

# Set backlight
alias backlight_350='backlight 350'
alias backlight_500='backlight 500'
alias backlight_1000='backlight 1000'
backlight() {
	sudo sh -c "
		echo ${1:-500} > /sys/class/backlight/intel_backlight/brightness
		echo 1 > /sys/class/backlight/acpi_video0/brightness
		echo 1 > /sys/class/backlight/acpi_video1/brightness
"
}
