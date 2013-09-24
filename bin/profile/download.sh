#!/bin/sh
DBG=""
URL="${1:?Please specify the URL to download}"
ACCOUNT="$2"
PASSWD="$3"
PROTO="${URL%://*}"
LONGPATH="${URL##*//}"
SERVER="${LONGPATH%%/*}"
SUBPATH="${LONGPATH#*/}"

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
if [ -z "$ACCOUNT" ]; then
	read -p "User: " ACCOUNT
else
	echo "User: $ACCOUNT"
fi
if [ -z "$PASSWD" ]; then
	trap "stty echo; trap '' SIGINT" SIGINT; stty -echo
	read -p "Password: " PASSWD; echo
	stty echo; trap "" SIGINT
else
	echo "Password already known"
fi

# Proceed with file transfer
case $TOOL in
	curl)
		${DBG} curl -u $ACCOUNT:$PASSWD -O "$URL" ;;
	wget)
		${DBG} wget --user="$ACCOUNT" --password="$PASSWD" "$URL" ;;
	ftp)
		${DBG} ftp -n -i -d <<END_SCRIPT
			open ${SERVER}
			user ${ACCOUNT}
			bin
			get ${SUBPATH}
			quit
END_SCRIPT
		;;
esac
exit 0
