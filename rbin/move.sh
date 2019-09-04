#!/bin/bash
GLOBIGNORE=""
SLEEP="30s"
STDOUT="/dev/null"
OPTS=""

# Args
while getopts "i:s:v" FLAG; do
  case "$FLAG" in
	i) GLOBIGNORE="${GLOBIGNORE:+${GLOBIGNORE}:}${OPTARG}";;
	s) SLEEP="${OPTARG}s";;
	v) STDOUT="/dev/stdout"; OPTS="-v --progress";;
	h) echo >&2 "Usage: `basename $0` [-i pattern] -- src dst"
	   echo >&2 "-i   bash ignore pattern"
	   echo >&2 "-s   sleep between verifications (in seconds)"
	   echo >&2 "-v   verbose mode"
	   exit 1
	   ;;
  esac
done
shift $(($OPTIND-1))
unset OPTIND OPTARG FLAG
SRC="${1:?Please specify the source directory or file}"
DST="${2:?Please specify the target directory or file}"

# Enable bash glob extension
shopt -s extglob
export GLOBIGNORE

# Main loop
while [ -e "$SRC" -a -e "$DST" ]; do 
	rsync --remove-source-files $OPTS "$SRC" "$DST" >"$STDOUT" 2>/dev/null
	sleep $SLEEP
	echo "Waiting for file ..." >"$STDOUT"
done
