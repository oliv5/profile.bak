#!/bin/sh
DBG=""
TOOL=""
OPTS=""

# Get args
while getopts "nt:o:" FLAG
do
  case "$FLAG" in
    n) DBG="echo";;
    o) OPTS="${OPTARG}";;
    t) TOOL="${OPTARG}";;
    h) echo >&2 "Usage: `basename $0` [-n] [-o options] [-t tool] URL account passwd"
       echo >&2 "-n   debug (do nothing)"
       echo >&2 "-o   download options (depends on tool chosen)"
       echo >&2 "-t   download tool"
       exit 1 ;;
  esac
done
shift $(($OPTIND-1))

# Build parameters
URL="${1:?Please specify the URL to download}"
ACCOUNT="$2"
PASSWD="$3"
PROTO="${URL%://*}"
LONGPATH="${URL##*//}"
SERVER="${LONGPATH%%/*}"
SUBPATH="${LONGPATH#*/}"

# Find the file transfer tool
if [ -z "$TOOL" ]; then
	if [ "$PROTO" = "ftp" ]; then
		TOOLS="curl ftp"
	else
		TOOLS="curl wget"
	fi
fi
for TOOL in $TOOLS; do
	if command -v $TOOL 2>&1 >/dev/null; then
		break;
	fi
	TOOL=""
done
if [ -z "$TOOL" ]; then
	echo "No tool available in [ $TOOLS ], cannot go on..."
	exit 1
fi

# Get Usename & password
echo "Server: $PROTO://$SERVER"
if [ -z "$ACCOUNT" ]; then
	read -p "User: " ACCOUNT
else
	echo "User: $ACCOUNT"
fi
if [ -z "$PASSWD" ]; then
	trap "stty echo; trap '' INT" INT; stty -echo
	#trap "stty echo; trap '' SIGINT" SIGINT; stty -echo
	read -p "Password: " PASSWD; echo
	#stty echo; trap "" SIGINT
	stty echo; trap INT
else
	echo "Password already known"
fi

# Proceed with file transfer
case $TOOL in
	curl)
		${DBG} curl ${OPTS} -u $ACCOUNT:$PASSWD -O "$URL" ;;
	wget)
		${DBG} wget ${OPTS} --user="$ACCOUNT" --password="$PASSWD" "$URL" ;;
	ftp)
		${DBG} ftp ${OPTS} -n -i -d <<END_SCRIPT
			open ${SERVER}
			user ${ACCOUNT}
			bin
			get ${SUBPATH}
			quit
END_SCRIPT
		;;
esac
exit 0
