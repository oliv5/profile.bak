#!/bin/bash

################################
# Install file notifier
alias write_notify='notify close_write'
alias read_notify='notify close_read'
alias rw_notify='notify "close_read,close_write"'
alias create_notify='notify create'
alias mv_notify='notify moved_to'
alias notify='_notify_file'

# Basic notification method with a loop
# Pros: file move is captured
# Cons: may miss event, high system resource consumption on large directories
_notify_loop() {
  local TRIGGER="${1:?No event to monitor}"
  local FILE="${2:?No dir/file to monitor}"
  shift 2
  local SCRIPT="${@:?No action to execute}"
  while true; do
    inotifywait -qq -e "$TRIGGER" "$FILE"
    eval "$SCRIPT"
  done
}

# Main notification method
# Pros: only a single inotifywait process & set of pipes
# Cons: does not capture file moves properly
_notify_proc() {
  local TRIGGER="${1:?No event to monitor}"
  local FILE="${2:?No dir/file to monitor}"
  shift 2
  local SCRIPT="${@:?No action to execute}"

  # Start child shell process, open pipes
  # Kill inotifywait when this process is killed
  if [ ${BASH_VERSION%%[^0-9]*} -ge 4 ]; then
    eval "
      coproc INOTIFY {
          inotifywait -q -m -e $TRIGGER \"$FILE\" &
          trap \"kill $!\" 1 2 3 6 15
          wait
      }"
  else
    echo "This bash version \"${BASH_VERSION%%[^0-9.]*}\" does not support coproc"
  fi

  # Kill the coproc child process when father is killed or interrupted
  trap "kill $INOTIFY_PID" 0 1 2 3 6 15

  ## Loop for each action
  while IFS=' ' read -ru ${INOTIFY[0]} DIR TRIGGER FILE; do # could use "read 0<&${INOTIFY[0]}"
    #echo "Event=$TRIGGER dir=$DIR file=$FILE exec=$SCRIPT"
    eval $SCRIPT
  done

  # Kill the coproc child process
  kill $INOTIFY_PID 2>/dev/null
}

# Main notification method enhencement to support file moves
# Monitor the root directory, filter events on file names
# Pros: uses _notify_proc low resource method
# Cons: it is triggered for every file event of the root directory
_notify_file() {
  local TRIGGER="${1:?No event to monitor}"
  local FILE="${2:?No dir/file to monitor}"
  shift 2
  local SCRIPT="${@:?No action to execute}"
  _notify_proc "$TRIGGER" "$(dirname "$FILE")" 'if [ "$(readlink -f "$DIR$FILE")" = "$(readlink -f "'$FILE'")" ]; then '$SCRIPT'; fi'
}

################################
# Disable bell
# https://wiki.archlinux.org/index.php/Disable_PC_speaker_beep
bell_off() {
  # In X
  xset -b
  # In console
  setterm -blength 0
}

################################
# Shell-mutex with pidfile
# https://jdimpson.livejournal.com/5685.html
mutex_flock() {
  # Open output 200 to the pid file
  local PIDFILE="${1:-/var/run}/$(basename "${0%.*}").pid"
  exec 200>"$PIDFILE" || return 1
  # Lock or die
  flock -n 200 || return 1
  # Store the pid
  echo $$ 1>&200
  echo "$PIDFILE"
  return 0
}
