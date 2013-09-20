#!/bin/sh

# Check prerequisites
command -v wget 2>&1 >/dev/null || (echo "Wget missing, cannot go on..." && exit 1)
command -v 7z 2>&1 >/dev/null || (echo "7z missing, cannot go on..." && exit 1)

# Goto home directory
cd $HOME

# Download .sshpack
echo "Sshpack download via HTTP"
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Passwd: " HTTPPASSWD
stty echo; trap "" SIGINT
wget --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack.7z
[ -f sshpack.7z ] || exit 2

# Install sshpack
7z x sshpack.7z

# Delete sshpack archive
rm sshpack.7z

# Set permissions on .sshpack
find sshpack/ -type d -execdir chmod 700 {} \;
find sshpack/ -type f -execdir chmod 600 {} \;
find sshpack/ -type f -name "*.sh" -execdir chmod +x {} \;
