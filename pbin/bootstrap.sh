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
# Ask for private directory
read -p "Enter private data directory in \$HOME: " PRIVATE
export PRIVATE="$HOME/${PRIVATE:-private}"
mkdir -p "$PRIVATE"

###################
# Download and install vcsh if not already there
if ! command -v vcsh >/dev/null 2>&1; then
	read -p "Clone vcsh ? (y/n) " REPLY
	if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
		git clone --depth 1 https://github.com/RichiH/vcsh.git "$HOME/bin/vcsh"
	fi
fi

# Clone profile repository
cd "$HOME"
read -p "Clone profile ? (y/n) " REPLY
if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
	vcsh clone https://github.com/oliv5/profile.git || 
		{ vcsh profile pull; vcsh profile reset --hard; } || 
		exit 0
fi
#{
#	TMPDIR="$(mktemp -d)"
#	echo "Move existing files into backup directory: $TMPDIR"
#	vcsh profile ls-files --with-tree=origin/master -c | 
#		while IFS='\0' read F; do
#			[ -e "$F" ] && mv "$F" "$TMPDIR/"
#		done
#	vcsh profile pull
#	vcsh profile reset --hard
#}

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
	mkdir -p bin/externals
	curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/externals/repo" && 
		chmod a+x "$HOME/bin/externals/repo"
	git clone https://gerrit.googlesource.com/git-repo "$HOME/bin/git-repo" && 
		chmod a+x "$HOME/bin/git-repo/repo"
fi
