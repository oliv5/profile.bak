#!/bin/sh

# Launch command in termux
# https://www.reddit.com/r/tasker/comments/86xqm9/run_tasker_task_via_adbshelltermux/
termux_cmd() {
  local TASK="${1:?No command specified...}"
  local PARAM1="${2}"
  local PARAM2="${3}"
  am broadcast --user 0 -a net.dinglish.tasker.run_task -e task "$TASK" ${PARAM1:+-e par1 "$PARAM1"} ${PARAM2:+-e par2 "$PARAM2"}
}
