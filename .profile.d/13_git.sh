#!/bin/bash

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

# Meld called by git
function git-meld() {
  meld "$2" "$5"
}

function git-stash-push() {
  git stash save --include-untracked "stash-$(date +%Y%m%d-%H%M)${1:+_$1}" && git stash apply stash@{0}
}

# Export a CL
function git-export() {
  git diff --name-only ${1:-HEAD} "${@:2}" | xargs --no-run-if-empty 7z a ${OPTS_7Z} "${GIT_ROOT:-.}/.gitbackup/export_$(date +%s).7z"
  #git diff-tree -r --no-commit-id --name-only --diff-filter=ACMRT ${1:-HEAD} | xargs tar -rf mytarfile.tar
}

# Import a CL
function git-import() {
  # Extract with full path
  7z x "${1:?Please specify the imported archive. Abort...}" -o"${GIT_ROOT:-.}"
}

# Suspend a CL
function git-suspend() {
  if git-export "$@"; then
    git reset --hard ${1:-HEAD} "${@:2}"
  fi
}

# Resume a CL
function git-resume() {
  if git diff-index --quiet HEAD --; then
      git-import "$1"
  else
      echo "Your repository has local changes. Cannot resume CL safely..."
  fi
}

# Revert to a given CL
function git-revert() {
  git reset --hard ${1:-HEAD} "${@:2}"
}

# Clean repo back to given CL
# remove unversionned files
function git-clean() {
  # Confirmation
  echo -n "We are going to remove unversioned files. Go on? (y/n): "
  read ANSWER; [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && exit 0
  # Clean repository
  git clean "$@"
}
