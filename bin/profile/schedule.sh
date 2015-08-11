#!/bin/sh
DBG=""
AT=""
AT_OPT="-M"
BATCH=""
TIMEOUT=""
TIMEOUT_OPT=""
RETRY=""
RETRY_OPT=0
WATCH=""
VERBOSE=""

# Convert OPTARG into seconds
arg2Sec(){
  OPTARG="$(echo "$OPTARG" | awk -F'[:.]' '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }')"
  if [ $OPTARG -eq 0 ]; then
    echo "Invalid '-$OPTFLAG' parameter. Abort..."
    exit 2
  fi
}

# Get args
OPTIND=0
unset OPTFLAG OPTARG OPTERR
while getopts "t:mbw:l:k:s:r:p:hdv" OPTFLAG
do
  case "$OPTFLAG" in
    t) AT="${OPTARG}";;
    m) AT_OPT="${AT_OPT:+$AT_OPT }-m";;
    b) BATCH="batch";;
    
    w) arg2Sec; WATCH="-n ${OPTARG}";;
    
    l) arg2Sec; TIMEOUT="${OPTARG}";;
    k) arg2Sec; TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-k ${OPTARG}";;
    s) TIMEOUT_OPT="${TIMEOUT_OPT:+$TIMEOUT_OPT }-s ${OPTARG}";;
    
    r) RETRY="${OPTARG}";;
    p) arg2Sec; RETRY_OPT="${OPTARG}";;
    
    d) DBG="echo";;
    v) VERBOSE="x";;
    
    h|*) echo >&2 "Usage: `basename $0` [-t time] [-m] [-b] [-w h:m:s] [-l h:m:s] [-k h:m:s] -[s signal] [-r trials] [-p h:m:s] -- <command line...>"
       echo >&2 "-t   at: start time (man at)"
       echo >&2 "-m   at: send email upon completion"
       echo >&2 "-b   batch: execute when system load < 1.5%"
       echo >&2 "-w   watch: re-schedule interval"
       echo >&2 "-l   timeout: timeout length"
       echo >&2 "-k   timeout: kill delay upon timeout"
       echo >&2 "-s   timeout: kill signal name sent upon timeout"
       echo >&2 "-r   retry: nb of retries upon failure (-1 inf)"
       echo >&2 "-p   retry: pause/delay between each trial"
       echo >&2 "-d   enable debug mode"
       echo >&2 "-v   enable verbose mode"
       echo >&2 "...  command line to execute"
       exit 1
       ;;
  esac
done
shift $(($OPTIND-1))
unset OPTFLAG OPTARG OPTERR
CMDLINE="$@"
OPTIND=0

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
  (set -${VERBOSE}; ${DBG} eval "${CMDLINE}")
else
  (set -${VERBOSE}; ${DBG} ${CMDLINE})
fi
exit 0
