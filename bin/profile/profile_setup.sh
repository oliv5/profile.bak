#!/bin/sh

# Check prerequisites
command -v git 2>&1 >/dev/null || echo "Git missing, cannot go on..." && exit 1
command -v wget 2>&1 >/dev/null || echo "Wget missing, cannot go on..." && exit 1
command -v 7z 2>&1 >/dev/null || echo "7z missing, cannot go on..." && exit 1

# Goto home directory
cd $HOME

# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	git clone https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	export PATH="$PATH:$HOME/bin/vcsh"
fi

# Get profile repository
vcsh clone https://github.com/oliv5/profile.git

# Download .sshpack
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Password: " HTTPPASSWD
stty echo; trap "" SIGINT
wget --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack_cfg.7z

# Install .sshpack
7z x sshpack_cfg.7z

# Delete .sshpack archive
rm sshpack_cfg.7z
