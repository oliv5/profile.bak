#!/bin/sh

# Check prerequisites
command -v wget 2>&1 >/dev/null || (echo "Wget missing, cannot go on..." && exit 1)
command -v 7z 2>&1 >/dev/null || (echo "7z missing, cannot go on..." && exit 1)

# Goto home directory
cd $HOME

# Download complete profile
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Password: " HTTPPASSWD
stty echo; trap "" SIGINT
wget --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/profile.7z

# Install profile
7z x profile.7z

# Delete sshpack archive
rm profile.7z

# Set permissions on .sshpack
chmod 700 .sshpack/
