#!/bin/sh

# Check prerequisites
command -v git 2>&1 >/dev/null || (echo "Git missing, cannot go on..." && exit 1)

# Goto home directory
cd "$HOME"
mkdir -p bin/externals 2>/dev/null

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

# Download and install google repo if not already there
if ! command -v repo >/dev/null 2>&1; then
	curl https://storage.googleapis.com/git-repo-downloads/repo > "$HOME/bin/externals/repo" && chmod a+x "$HOME/bin/externals/repo"
	git clone https://gerrit.googlesource.com/git-repo "$HOME/bin/git-repo" && chmod a+x "$HOME/bin/git-repo/repo"
	export PATH="$PATH:$HOME/bin/externals:$HOME/bin/git-repo"
fi

# Clone profile repository
vcsh clone https://github.com/oliv5/profile.git

# Clone external repositories
repo init -u https://github.com/oliv5/manifests.git -m bin.xml
