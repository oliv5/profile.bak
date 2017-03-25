#!/bin/sh

# List devices
xrandr_ls() {
  xrandr -q | awk '/connected/ {print $1}'
}
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

# Get current device
xrandr_device() {
  xrandr -q | awk '/connected/{d=$1}/*/{print d}'
}
xrandr_current() {
  xrandr -q | awk '/connected/{d=$1}/*/{print d "\t" $1}'
}

# Screen resolution
xrandr_size() {
  if [ $# -ge 0 ]; then
    xrandr -q | awk '/*/{print $1}'
  else
    xrandr -s "$@"
  fi
}
alias xrandr_getres='xrandr_size;'
alias xrandr_getsize='xrandr_size;'
alias xrandr_setres='xrandr_size'
alias xrandr_setsize='xrandr_size'
alias xrandr_refresh='xrandr_size 0'
alias xrandr_1600='xrandr_size 1600x1200'
alias xrandr_1360='xrandr_size 1360x768'
alias xrandr_1280='xrandr_size 1280x1024'
alias xrandr_1024='xrandr_size 1024x768'
alias xrandr_800='xrandr_size 800x600'
alias xrandr_640='xrandr_size 640x480'

# Enable display
alias xrandr_auto='xrandr_en'
xrandr_en() {
  #See options like --dryrun, --mode 1024x768
  local ARG1="$1"; shift $(min 1 $#)
  xrandr --output "${ARG1:-$(xrandr_connected | head -n 1)}" --auto "$@"
}

# Disable display
xrandr_dis() {
  local ARG1="$1"; shift $(min 1 $#)
  xrandr --output "${ARG1:-$(xrandr_connected | head -n 1)}" --off "$@"
}

# Set backlight
alias backlight_250='backlight 250'
alias backlight_350='backlight 350'
alias backlight_500='backlight 500'
alias backlight_1000='backlight 1000'
backlight_reset() {
	sudo sh -c "
		echo 1 > /sys/class/backlight/acpi_video0/brightness
		echo 1 > /sys/class/backlight/acpi_video1/brightness
"
}
backlight() {
	sudo sh -c "echo ${1:-500} > /sys/class/backlight/intel_backlight/brightness"
}
