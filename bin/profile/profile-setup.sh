#!/bin/sh

# Check prerequisites
command -v git 2>&1 >/dev/null || (echo "Git missing, cannot go on..." && exit 1)

# Goto home directory
cd "$HOME"
mkdir bin 2>/dev/null

# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	git clone https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	export PATH="$PATH:$HOME/bin/vcsh"
fi

# Download and install mr if not already there
if ! command -v mr >/dev/null 2>&1; then
	git clone https://github.com/joeyh/myrepos.git "$HOME/bin/mr"
	export PATH="$PATH:$HOME/bin/mr"
fi

# Get profile repository
vcsh clone ssh://olivier@oliv5kta.dtdns.net:443/home/olivier/git/profile.git ||
vcsh clone https://github.com/oliv5/profile.git
