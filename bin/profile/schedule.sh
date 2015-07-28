#!/bin/sh
DGB=""
AT=""
AT_OPT="-M"
BATCH=""
TIMEOUT=""
TIMEOUT_OPT=""
RETRY=""
RETRY_OPT=0
WATCH=""

# Get args
while getopts "t:mbw:l:k:s:r:p:h" FLAG
do
  case "$FLAG" in
    t) AT="${OPTARG}";;
    m) AT_OPT="${AT_OPT:+$AT_OPT }-m";;
    b) BATCH="batch";;
    
    w) WATCH="-n ${OPTARG}";;
    
    l) TIMEOUT="${OPTARG}";;
    k) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-k ${OPTARG}";;
    s) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-s ${OPTARG}";;
    
    r) RETRY="${OPTARG}";;
    p) RETRY_OPT="${OPTARG}";;
    
    h|*) echo >&2 "Usage: `basename $0` [-t time] [-m] [-b] [-w seconds] [-l seconds] [-k seconds] -[s signal] [-r trials] [-p pause] -- <command line...>"
       echo >&2 "-t   at: time of execution (man at)"
       echo >&2 "-m   at: send email upon completion"
       echo >&2 "-b   batch: execute when system load < 1.5%"
       echo >&2 "-w   watch: execute every N seconds"
       echo >&2 "-l   timeout: timeout length in seconds"
       echo >&2 "-k   timeout: kill after N seconds upon timeout"
       echo >&2 "-s   timeout: signal name to send upon timeout"
       echo >&2 "-r   retry: retry N times upon failure (-1 inf)"
       echo >&2 "-p   retry: pause S seconds between each trial"
       echo >&2 "...  command line to execute"
       exit 1
       ;;
  esac
done
shift $(($OPTIND-1))
CMDLINE="$@"

# Build control command lines
AT="${BATCH:-${AT:+at $AT $AT_OPT}}"
WATCH="${WATCH:+watch $WATCH}"
TIMEOUT="${TIMEOUT:+timeout $TIMEOUT_OPT $TIMEOUT}"
RETRY="${RETRY:+retry.sh $RETRY $RETRY_OPT}"

# Build the final command-line and execute
CMDLINE="${CMDLINE:-false}"
[ ! -z "$RETRY" ] && CMDLINE="${RETRY} ${CMDLINE}"
[ ! -z "$TIMEOUT" ] && CMDLINE="${TIMEOUT} sh -c '${CMDLINE}'"
[ ! -z "$WATCH" ] && CMDLINE="${WATCH} -- ${CMDLINE}"
if [ ! -z "$AT" ]; then
  CMDLINE="$(printf "${AT} <<EOF\n${CMDLINE}\nEOF\n")"
  ${DGB} eval "${CMDLINE}"
else
  ${DGB} ${CMDLINE}
fi
exit 0
