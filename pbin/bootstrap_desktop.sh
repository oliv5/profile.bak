#!/bin/sh

###################
# Check prerequisites
if ! command -v git 2>&1 >/dev/null; then 
	echo "Git missing, cannot go on..."
	exit 1
fi

###################
# Ask for private directory
read -p "Enter private data directory in \$HOME: " PRIVATE
export PRIVATE="$HOME/$PRIVATE"
mkdir -p "$PRIVATE"

###################
# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	git clone https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	export PATH="$PATH:$HOME/bin/vcsh"
fi

# Clone profile repository
cd "$HOME"
vcsh clone https://github.com/oliv5/profile.git

###################
# Download and install mr if not already there
if ! command -v mr >/dev/null 2>&1; then
	git clone https://github.com/joeyh/myrepos.git "$HOME/bin/mr"
	export PATH="$PATH:$HOME/bin/mr"
fi

# Checkout mr repositories
cd "$HOME"
mr checkout

###################
# Download and install google repo if not already there
if ! command -v repo >/dev/null 2>&1; then
	mkdir -p bin/externals
	curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/externals/repo" && 
		chmod a+x "$HOME/bin/externals/repo"
	git clone https://gerrit.googlesource.com/git-repo "$HOME/bin/git-repo" && 
		chmod a+x "$HOME/bin/git-repo/repo"
	export PATH="$PATH:$HOME/bin/externals:$HOME/bin/git-repo"
fi

# Setup bin repos
read -p "Setup bin repos ? (y/n)" REPLY
if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
	mkdir -p "$HOME/bin"
	cd "$HOME/bin"
	repo init -u https://github.com/oliv5/manifests.git -m bin.xml
	repo sync -c
fi

# Setup dev repos
read -p "Setup dev repos ? (y/n)" REPLY
if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
	mkdir -p "${PRIVATE:-$HOME}/dev"
	cd "${PRIVATE:-$HOME}/dev"
	repo init -u https://github.com/oliv5/manifests.git -m dev.xml
fi
