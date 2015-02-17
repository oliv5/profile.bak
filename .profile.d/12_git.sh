#!/bin/sh

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

# Status aliases
alias gs='git status'
alias gl='git ls-files'
alias gm='git ls-files -m'
alias gc='git ls-files -u'
alias gd='git ls-files -d'
alias gn='git ls-files -o --exclude-standard'
alias gu='git ls-files -o'
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
# git add new files
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add $(git ls-files -o)'

########################################
# Meld called by git
git-meld() {
  meld "$2" "$5"
}

########################################
# Get git repo root directory
git-root() {
  git rev-parse --show-toplevel
}

# Check commit existenz
git-exists() {
  git rev-parse --verify "${1:-HEAD}" 2>&1 >/dev/null
}

# Check if a repo has been modified
git-modified() {
  ! git diff-index --quiet HEAD --
}

########################################
# Push changes onto stash, revert changes
git-stash-push() {
  git stash save "stash-$(date +%Y%m%d-%H%M)${1:+_$1}"
}

# Push changes onto stash, does not revert anything
git-stash-save() {
  git-stash-push "$@" && git stash apply stash@{0} >/dev/null
}

# Pop change from stash
git-stash-pop() {
  git stash pop stash@{${1:-0}}
}

# Apply change from stash
git-stash-apply() {
  git stash apply stash@{${1:-0}}
}

# Aliases using stashes
alias git-export='git-stash-save'
alias git-import='git-stash-apply'
alias git-suspend='git-stash-push'
alias git-resume='git-stash-pop'

########################################
# Hard revert to a given CL or revert a file
git-revert() {
  if [ -f "$1" -o -f "$2" ]; then
    git checkout -- "$@"
  else
    REV="${1:-HEAD}"; shift; ARGS="$@"
    git reset --hard "$REV" "$ARGS"
  fi
}

# Soft revert to a given CL, won't change modified files
git-rollback() {
  REV="${1:-HEAD}"; shift; ARGS="$@"
  git reset "$REV" "$ARGS"
}

# Clean repo back to given CL
# remove unversionned files
git-clean() {
  # Confirmation
  if [ "$1" != "-y" ]; then
    echo -n "Remove unversioned files? (y/n): "
    read ANSWER; [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && return 0
  fi
  # Clean repository
  git clean "$@"
}

########################################
# List files
git-ls() {
  git ls-tree -r ${1:-master} --name-only ${2:+| grep -F "$2"}
}

# Amend author/committer names & emails
git-amend-names() {
  # Identify who/what the amend is about
  local AUTHOR_1="${1%%:*}"
  local AUTHOR_2="${1##*:}"
  local AUTHOR_EMAIL_1="${2%%:*}"
  local AUTHOR_EMAIL_2="${2##*:}"
  local COMMITTER_1="${3%%:*}"
  local COMMITTER_2="${3##*:}"
  local COMMITTER_EMAIL_1="${4%%:*}"
  local COMMITTER_EMAIL_2="${4##*:}"
  # Display what is going to be done
  echo "Replace author name '$AUTHOR_1' by '$AUTHOR_2'"
  echo "Replace author email '$AUTHOR_EMAIL_1' by '$AUTHOR_EMAIL_2'"
  echo "Replace committer name '$COMMITTER_1' by '$COMMITTER_2'"
  echo "Replace committer email '$COMMITTER_EMAIL_1' by '$COMMITTER_EMAIL_2'"
  # Write the script
  local SCRIPT='
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

# Git history
git-history() {
  git log -p "$@"
}

# Git add gitignore
git-ignore-add() {
  grep "$1" .gitignore >/dev/null || echo "$1" >>.gitignore
}

# Git list gitignore
git-ignore-list() {
  git status -s --ignored 2>/dev/null || git clean -ndX
}

# Git ignore changes
git-ignore-changes() {
  git update-index --assume-unchanged "$@"
}
git-noignore-changes() {
  git update-index --no-assume-unchanged "$@"
}
