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

# Convert the input into seconds
toSec(){
  echo "$1" | awk -F'[:.]' '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }'
}

# Get args
while getopts "t:mbw:l:k:s:r:p:h" FLAG
do
  case "$FLAG" in
    t) AT="${OPTARG}";;
    m) AT_OPT="${AT_OPT:+$AT_OPT }-m";;
    b) BATCH="batch";;
    
    w) WATCH="-n $(toSec ${OPTARG})";;
    
    l) TIMEOUT="$(toSec ${OPTARG})";;
    k) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-k $(toSec ${OPTARG})";;
    s) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-s ${OPTARG}";;
    
    r) RETRY="${OPTARG}";;
    p) RETRY_OPT="$(toSec ${OPTARG})";;
    
    h|*) echo >&2 "Usage: `basename $0` [-t time] [-m] [-b] [-w h:m:s] [-l h:m:s] [-k h:m:s] -[s signal] [-r trials] [-p h:m:s] -- <command line...>"
       echo >&2 "-t   at: time of execution (man at)"
       echo >&2 "-m   at: send email upon completion"
       echo >&2 "-b   batch: execute when system load < 1.5%"
       echo >&2 "-w   watch: execution time delay"
       echo >&2 "-l   timeout: timeout length"
       echo >&2 "-k   timeout: kill delay upon timeout"
       echo >&2 "-s   timeout: kill signal name sent upon timeout"
       echo >&2 "-r   retry: nb of retries upon failure (-1 inf)"
       echo >&2 "-p   retry: pause/delay between each trial"
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
