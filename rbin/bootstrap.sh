#!/bin/sh
# Run with cmd: (curl https://raw.githubusercontent.com/oliv5/profile/master/rbin/bootstrap.sh -L | sh)
set -e

###################
# Check prerequisites
if ! command -v git 2>&1 >/dev/null; then 
	echo "Git is missing, cannot go on..."
	exit 1
fi

###################
# Setup private data folder
while [ ! -d "$PRIVATE" ]; then
	read -p "Private data directory in \$HOME (empty is '\$HOME'): " PRIVATE
	export PRIVATE="$HOME/${PRIVATE}"
	mkdir -p "$PRIVATE"
fi
if [ "$PRIVATE" != "$HOME" ]; then
    export HOME="${PRIVATE}/home"
fi

###################
# Setup the expected path
export PATH="$PATH:$HOME/bin:$HOME/bin/vcsh:$HOME/bin/mr:$HOME/bin/external"

###################
# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	read -p "Clone vcsh ? (y/n) " REPLY
	if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
		git clone --depth 1 https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	fi
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
# Clone profile repository
read -p "Clone profile ? (y/n) " REPLY
if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
    URL="https://github.com/oliv5/profile.git"
	cd "$HOME"
	if [ "$PRIVATE" = "$HOME" ]; then
	    vcsh clone "$URL" profile
    else
        git clone "$URL" "$PRIVATE/profile"
    fi
fi

###################
# Clone home repository
read -p "Home repository URL (empty to skip): " REPLY
if [ -n "$REPLY" ]; then
	URL="$REPLY"
	cd "$HOME"
	if [ "$PRIVATE" = "$HOME" ]; then
	    vcsh clone "$URL" home
	else
	    git clone "$URL" "$PRIVATE/home"
	fi
fi

###################
# Checkout remaining repositories
read -p "Clone remaining repositories ? (y/n) " REPLY
if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
	mr checkout
fi
