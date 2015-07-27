#!/bin/sh
DGB=""
AT=""
AT_OPT="-M"
BATCH=""
TIMEOUT=""
TIMEOUT_OPT=""
RETRY=""
RETRY_OPT=0

# Get args
while getopts "t:mbl:k:s:r:p:h" FLAG
do
  case "$FLAG" in
    t) AT="${OPTARG}";;
    m) AT_OPT="${AT_OPT:+$AT_OPT }-m";;
    b) BATCH="batch";;
    
    l) TIMEOUT="${OPTARG}";;
    k) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-k ${OPTARG}";;
    s) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-s ${OPTARG}";;
    
    r) RETRY="${OPTARG}";;
    p) RETRY_OPT="${OPTARG}";;
    
    h) echo >&2 "Usage: `basename $0` [-t time] [-m] [-b] [-l length] [-k time] -[s signal] [-r trials] [-p pause] -- <command line...>"
       echo >&2 "-t   at: time of execution (man at)"
       echo >&2 "-m   at: send email upon completion"
       echo >&2 "-b   batch: execute when system load < 1.5%"
       echo >&2 "-l   timeout: timeout length (s/m/h/d)"
       echo >&2 "-k   timeout: kill after N sec upon timeout"
       echo >&2 "-s   timeout: signal name to send upon timeout"
       echo >&2 "-r   retry: retry N times upon failure"
       echo >&2 "-p   retry: pause S sec between each trial"
       echo >&2 "...  command line to execute"
       exit 1
       ;;
  esac
done
shift $(($OPTIND-1))
CMDLINE="$@"

# Build control command lines
AT="${BATCH:-${AT:+at $AT $AT_OPT}}"
TIMEOUT="${TIMEOUT:+timeout $TIMEOUT_OPT $TIMEOUT }"
RETRY="${RETRY:+retry.sh $RETRY $RETRY_OPT }"

# Build the final command line
CMDLINE="${CMDLINE:+${AT:+${AT} <<EOF\n}${TIMEOUT}${RETRY}${CMDLINE}${AT:+\nEOF\n}}"
${DGB} eval "$(printf "$CMDLINE")"
exit 0
