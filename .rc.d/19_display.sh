#!/bin/sh

# List devices
alias xrandr_ls="xrandr -q | awk '/connected/ {print \$1}'"
alias xrandr_connected="xrandr -q | awk '/ connected/{print \$1}'"
alias xrandr_disconnected="xrandr -q | awk '/disconnected/{print \$1}'"
alias xrandr_on="xrandr -q | awk '/ connected/{name=\$1} /*/{print name}'"
alias xrandr_off="xrandr -q | awk 'BEGIN{name=\"\"} / connected/{if (length(name)>0) {print name}; name=\$1} /*/{name=\"\"} END{if (length(name)>0) {print name}}'"
alias xrandr_cfg="xrandr -q | awk '/connected/{d=\$1}/*/{print d \"\t\" \$1}'"

# Screen resolution
xrandr_size() {
  if [ $# -eq 0 ]; then
    xrandr -q | awk '/*/{print $1}'
  else
    xrandr -s "$@"
  fi
}
alias xrandr_getres='xrandr_size;'
alias xrandr_getsize='xrandr_size;'
alias xrandr_setres='xrandr_size'
alias xrandr_setsize='xrandr_size'
#alias xrandr_auto='xrandr_size 0'
alias xrandr_refresh='xrandr_size 0'
alias xrandr_1600='xrandr_size 1600x1200'
alias xrandr_1360='xrandr_size 1360x768'
alias xrandr_1280='xrandr_size 1280x1024'
alias xrandr_1024='xrandr_size 1024x768'
alias xrandr_800='xrandr_size 800x600'
alias xrandr_640='xrandr_size 640x480'

# Enable/disable screen
xrandr_auto() {
  local SCREEN="${1:?No screen specified...}"
  shift
  xrandr --output "${SCREEN}" --auto "$@"
}
xrandr_enable() {
  local SCREEN="${1:?No screen specified...}"
  local MODE="${2:?No mode specified... ex: 1024x768}"
  shift 2
  xrandr --output "${SCREEN}" --mode "${MODE}" "$@"
}
xrandr_disable() {
  local SCREEN="${1:?No screen specified...}"
  shift
  xrandr --output "${SCREEN}" --off "$@"
}

# Set scale
xrandr_scale() {
  local SCREEN="${1:?No screen specified...}"
  local SCALE="${2:-1x1}"
  shift 2
  xrandr --output "${SCREEN}" --scale "$SCALE" "$@"
}

# Set position
xrandr_pos() {
  local SCREEN1="${1:?No screen specified...}"
  local POS="${2:?No position specified...}"
  local SCREEN2="${3:?No screen specified...}"
  shift 3
  xrandr --output "${SCREEN2}" --${POS}-of "${SCREEN1}" "$@"
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

