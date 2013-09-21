#!/bin/sh
FILE="${1:?Please specify the file to upload}"
URL="${2:?Please specify the URL to upload to}"
URL_UPLOAD_SCRIPT="${3}${FILE}"
PROTO="${URL%://*}"
PATH="${URL#*//}"
SERVER="${PATH%%/*}"
SUBPATH="${PATH#*/}"
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
echo "Protocol: $PROTO"
read -p "User: " ACCOUNT
trap "stty echo; trap '' SIGINT" SIGINT; stty -echo
read -p "Password: " PASSWD
stty echo; trap "" SIGINT

# Proceed with file transfer
case $TOOL in
	curl)
		if [ "$PROTO" == "ftp" ]; then
			curl -u $ACCOUNT:$PASSWD -T "$FILE" "$URL" ;;
		else
			curl -u $ACCOUNT:$PASSWD "$URL_UPLOAD_SCRIPT" ;;
		fi
	wget)
		wget --user="$ACCOUNT" --password="$PASSWD" "$URL_UPLOAD_SCRIPT" ;;
	ftp)
		ftp -n -i -d <<END_SCRIPT
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
