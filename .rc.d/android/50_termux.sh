#!/bin/sh

# Launch command in termux
# https://www.reddit.com/r/tasker/comments/86xqm9/run_tasker_task_via_adbshelltermux/
termux_cmd() {
  local TASK="${1:?No command specified...}"
  local PARAM1="${2}"
  local PARAM2="${3}"
  adb shell am broadcast --user 0 -a net.dinglish.tasker.run_task -e task "$TASK" ${PARAM1:+-e par1 "$PARAM1"} ${PARAM2:+-e par2 "$PARAM2"}
}

# Send termux type cmd
adb_termux_type_cmd() {
    adb shell am start -n com.termux/.app.TermuxActivity &&
    adb shell input text "$@" &&
    adb shell input keyevent 113 &&
    adb shell input keyevent 66
}
