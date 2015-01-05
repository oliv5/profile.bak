#!/bin/bash

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

# Status aliases
alias gs='git status'
alias gm='git ls-files -m'
alias gc='git ls-files -u'
alias gd='git ls-files -d'
alias gn='git ls-files -o --exclude-standard'
# Diff aliases
alias gdd='git diff'
alias gdm='git difftool -y -t meld --'
alias gds='git stash show -t'
# Stash aliases
alias gsc='git-stash-push'
alias gss='git-stash-save'
alias gsb='git-stash-save --include-untracked'
alias gsp='git-stash-pop'
alias gsa='git-stash-apply'
alias gsl='git stash list'
# Commit aliases
alias git-ci='git commit'
# Gitignore
alias gil='git-ignore-list'
alias gia='git-ignore-add'

# Meld called by git
function git-meld() {
  meld "$2" "$5"
}

# Check if a repo has been modified
function git-modified() {
  ! git diff-index --quiet HEAD --
}

# Push changes onto stash, revert changes
function git-stash-push() {
  git stash save "stash-$(date +%Y%m%d-%H%M)${1:+_$1}"
}

# Push changes onto stash, does not revert anything
function git-stash-save() {
  git-stash-push "$@" && git stash apply stash@{0} >/dev/null
}

# Pop change from stash
function git-stash-pop() {
  git stash pop stash@{${1:-0}}
}

# Apply change from stash
function git-stash-apply() {
  git stash apply stash@{${1:-0}}
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
  # Look for modified repo
  if [ -z "$GIT_YES" -a git-modified ]; then
    echo -n "Your repository has local changes, proceed anyway? (y/n): "
    read ANSWER
    if [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ]; then
      return
    fi
  fi
  # Import CL
  git-import "$1"
}

# Hard revert to a given CL or revert a file
function git-revert() {
  if [ -f "$1" -o -f "$2" ]; then
    git checkout -- "$@"
  else
    git reset --hard ${1:-HEAD} "${@:2}"
  fi
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
function git-exists() {
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

# Git history
function git-history() {
  git log -p "$@"
}

# Git add gitignore
function git-ignore-add() {
  grep "$1" .gitignore >/dev/null || echo "$1" >>.gitignore
}

# Git list gitignore
function git-ignore-list() {
  git status -s --ignored 2>/dev/null || git clean -ndX
}
