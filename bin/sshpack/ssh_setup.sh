#!/bin/sh

# Check prerequisites
command -v wget 2>&1 >/dev/null || echo "Wget missing, cannot go on..." && exit 1
command -v 7z 2>&1 >/dev/null || echo "7z missing, cannot go on..." && exit 1

# Goto home directory
cd $HOME

# Download .sshpack
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Password: " HTTPPASSWD
stty echo; trap "" SIGINT
wget --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack.7z

# Install sshpack
7z x sshpack.7z

# Delete sshpack archive
rm sshpack.7z
