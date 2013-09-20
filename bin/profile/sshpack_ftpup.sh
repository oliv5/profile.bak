#!/bin/sh
OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"
FTPHOST="ftpperso.free.fr"
FTPUSER="olivkta"
FTPPWD="/private/bin"
ARCHIVE="$HOME/sshpack.7z"

# Check prerequisites
command -v ftp 2>&1 >/dev/null || (echo "Ftp missing, cannot go on..." && exit 1)
command -v 7z 2>&1 >/dev/null || (echo "7z missing, cannot go on..." && exit 1)

# Got to HOME
cd ${HOME}

# Delete existing archive
rm "${ARCHIVE}" 2>/dev/null

# Compress profile
7z a $OPTS_7Z -mhe=on -p "${ARCHIVE}" "$HOME/sshpack"
[ ! -f ${ARCHIVE} ] && exit 2

# Push to server
ARCHIVE_NAME="$(basename ${ARCHIVE})"
ARCHIVE_VERSION="$(date +%Y%m%d_%H%M%S)"
ftp -n -i -d <<END_SCRIPT
  open ${FTPHOST}
  user ${FTPUSER}
  cd ${FTPPWD}
  bin
  put ${ARCHIVE_NAME}
  put ${ARCHIVE_NAME} ${ARCHIVE_NAME}.${ARCHIVE_VERSION}
  quit
END_SCRIPT

# Delete archive
rm "${ARCHIVE}"
