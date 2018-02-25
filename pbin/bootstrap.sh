#!/bin/sh
# Run with cmd: (curl https://raw.githubusercontent.com/oliv5/profile/master/pbin/bootstrap.sh -L | sh)
set -e

###################
# Check prerequisites
if ! command -v git 2>&1 >/dev/null; then 
	echo "Git is missing, cannot go on..."
	exit 1
fi

###################
# Setup the expected path
export PATH="$PATH:$HOME/bin:$HOME/bin/vcsh:$HOME/bin/mr"
export PATH="$PATH:$HOME/bin/externals:$HOME/bin/git-repo"

###################
# Setup private data folder
if [ ! -d "$PRIVATE" ]; then
	read -p "Private data directory in \$HOME (default is '\$HOME/private'): " PRIVATE
	export PRIVATE="$HOME/${PRIVATE:-private}"
	mkdir -p "$PRIVATE"
fi

###################
# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	read -p "Clone vcsh ? (y/n) " REPLY
	if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
		git clone --depth 1 https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	fi
fi

# Clone profile repository
read -p "Clone profile ? (y/n) " REPLY
if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
	cd "$HOME"
	vcsh clone https://github.com/oliv5/profile.git profile ||
		{ vcsh profile pull; vcsh profile reset --hard; } || 
		exit 0
fi

###################
# Download and install mr if not already there
if ! command -v mr >/dev/null 2>&1; then
	read -p "Clone mr ? (y/n) " REPLY
	if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
		git clone --depth 1 https://github.com/joeyh/myrepos.git "$HOME/bin/mr"
	fi
fi

###################
# Download and install google repo if not already there
if ! command -v repo >/dev/null 2>&1; then
	mkdir -p "$HOME/bin/externals"
	curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/externals/repo" && 
		chmod a+x "$HOME/bin/externals/repo"
	#git clone https://gerrit.googlesource.com/git-repo "$HOME/bin/git-repo" && 
	#	chmod a+x "$HOME/bin/git-repo/repo"
fi

###################
# Clone home repository
read -p "Home repository URL (enpty to skip): " REPLY
if [ -n "$REPLY" ]; then
	cd "$HOME"
	vcsh clone "$REPLY"
fi

###################
# Checkout remaining repositories
read -p "Clone remaining repositories ? (y/n) " REPLY
if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
	mr checkout
fi
