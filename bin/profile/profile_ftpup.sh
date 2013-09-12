#!/bin/sh
OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"
FTPHOST="ftpperso.free.fr"
FTPUSER="olivkta"
FTPPWD="/private/bin"
ARCHIVE="$HOME/profile.7z"

# Check prerequisites
command -v ftp 2>&1 >/dev/null || (echo "Ftp missing, cannot go on..." && exit 1)
command -v 7z 2>&1 >/dev/null || (echo "7z missing, cannot go on..." && exit 1)

# Compress profile
vcsh profile ls-files "$HOME" | xargs 7z a $OPTS_7Z -mhe=on -p "${ARCHIVE}" "${HOME}/.sshpack"

# Push to server
ftp -n -i -d <<END_SCRIPT
  open ${FTPHOST}
  user ${FTPUSER}
  cd ${FTPPWD}
  bin
  put "${ARCHIVE}"
  put "${HOME}/bin/profile/profile_ftpdown.sh"
  quit
END_SCRIPT

# Delete profile archive
rm "${ARCHIVE}"
