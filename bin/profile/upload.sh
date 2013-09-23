#!/bin/sh
DBG=""
FILE="${1:?Please specify the file to upload}"
URL="${2:?Please specify the URL to upload to}"
PROTO="${URL%://*}"
LONGPATH="${URL#*//}"
SERVER="${LONGPATH%%/*}"
SUBPATH="${LONGPATH#*/}"
SUBDIR="${SUBPATH%/*}"
SUBFILE="${SUBPATH##*/}"

# Find the file transfer tool
if [ "$PROTO" == "ftp" ]; then
	TOOLS="curl ftp"
else
	TOOLS="curl wget"
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
read -p "User: " ACCOUNT
trap "stty echo; trap '' SIGINT" SIGINT; stty -echo
read -p "Password: " PASSWD; echo
stty echo; trap "" SIGINT

# Proceed with file transfer
case $TOOL in
	curl)
		if [ "$PROTO" == "ftp" ]; then
			${DBG} curl -v -u $ACCOUNT:$PASSWD -T "$FILE" "$URL"
		else
			${DBG} curl -v -u $ACCOUNT:$PASSWD "$URL"
		fi;;
	wget)
		${DBG} wget --user="$ACCOUNT" --password="$PASSWD" "$URL" ;;
	ftp)
		${DBG} ftp -n -i -d <<END_SCRIPT
			open ${SERVER}
			user ${ACCOUNT}
			cd ${SUBDIR}
			bin
			put ${FILE}
			ren $(basename $FILE) $SUBFILE
			quit
END_SCRIPT
		;;
esac
exit 0
