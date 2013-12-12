#!/bin/bash

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

# alias
alias gs='git status'
alias gd='git diff'
alias gdm='git difftool -y -t meld'

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

# Hard revert to a given CL
function git-revert() {
  git reset --hard ${1:-HEAD} "${@:2}"
}

# Soft revert to a given CL, won't change modified files
function git-rollback() {
  git reset ${1:-HEAD} "${@:2}"
}

# Clean repo back to given CL
# remove unversionned files
function git-clean() {
  # Confirmation
  if [ "$1" != "-y" ]; then
    echo -n "Remove unversioned files? (y/n): "
    read ANSWER; [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && return 0
  fi
  # Clean repository
  git clean "$@"
}

# List files
function git-ls() {
  git ls-tree -r ${1:-master} --name-only ${2:+| grep -F "$2"}
}

# Check commit existenz
function git-commit-exists() {
  git rev-parse --verify "${1:?Please enter a commit hash...}" 2>/dev/null
}

# Amend author/committer names & emails
function git-amend-names() {
  # Identify who/what the amend is about
  AUTHOR_1="${1%%:*}"
  AUTHOR_2="${1##*:}"
  AUTHOR_EMAIL_1="${2%%:*}"
  AUTHOR_EMAIL_2="${2##*:}"
  COMMITTER_1="${3%%:*}"
  COMMITTER_2="${3##*:}"
  COMMITTER_EMAIL_1="${4%%:*}"
  COMMITTER_EMAIL_2="${4##*:}"
  # Display what is going to be done
  echo "Replace author name '$AUTHOR_1' by '$AUTHOR_2'"
  echo "Replace author email '$AUTHOR_EMAIL_1' by '$AUTHOR_EMAIL_2'"
  echo "Replace committer name '$COMMITTER_1' by '$COMMITTER_2'"
  echo "Replace committer email '$COMMITTER_EMAIL_1' by '$COMMITTER_EMAIL_2'"
  # Write the script
  SCRIPT='
    if [ -z "$AUTHOR_1" -o "$GIT_AUTHOR_NAME" = "$AUTHOR_1" ]; then
      if [ -z "$AUTHOR_EMAIL_1" -o "$GIT_AUTHOR_NAME" = "$AUTHOR_EMAIL_1" ]; then
        if [ -z "$COMMITTER_1" -o "$GIT_AUTHOR_NAME" = "$COMMITTER_1" ]; then
          if [ -z "$COMMITTER_EMAIL_1" -o "$GIT_AUTHOR_NAME" = "$COMMITTER_EMAIL_1" ]; then
            [ "$GIT_AUTHOR_NAME" = "$AUTHOR_1" ] && export GIT_AUTHOR_NAME="$AUTHOR_2" || unset GIT_AUTHOR_NAME
            [ "$GIT_AUTHOR_EMAIL" = "$AUTHOR_EMAIL_1" ] && export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL_2" || unset GIT_AUTHOR_EMAIL
            [ "$GIT_COMMITTER_NAME" = "$COMMITTER_1" ] && export GIT_COMMITTER_NAME="$COMMITTER_2" || unset GIT_COMMITTER_NAME
            [ "$GIT_COMMITTER_EMAIL" = "$COMMITTER_EMAIL_1" ] && export GIT_COMMITTER_EMAIL="$COMMITTER_EMAIL_2" || unset GIT_COMMITTER_EMAIL
          fi
        fi
      fi
    fi
  '
  # Execute the script
  git filter-branch --env-filter "$SCRIPT"
}

# Git commit
function git-ci() {
  git reset HEAD
  git add "$@"
  git commit
}
