#!/bin/bash

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

function git-stash-push() {
  git stash save --include-untracked “backup-$(date +%Y%m%d-%H%M)${1:+_$1}” && git stash apply stash@{0}
}

function git-export() {
  git diff --name-only ${2:-HEAD} ${3} | xargs 7z a ${OPTS_7Z} ${1:-${GIT_ROOT:-.}/git-export_$(date +%s).7z}
  #git diff-tree -r --no-commit-id --name-only --diff-filter=ACMRT ${1:-HEAD} | xargs tar -rf mytarfile.tar
}

function git-import() {
  # Goto SVN directory
  OPWD=$PWD
  cd ${GIT_ROOT:-./}
  # Extract with full path
  7z x "$1"
  # Cleanup
  cd $OPWD
}

function git-meld() {
  meld "$2" "$5"
}
