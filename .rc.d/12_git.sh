#!/bin/sh

export GIT_EDITOR="vim"
export GIT_PAGER="cat"

########################################
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
# Merge aliases
alias gmm='git mergetool -y -t meld --'
# Stash aliases
alias gsc='git_stash_push'
alias gss='git_stash_save'
alias gsb='git_stash_save --include-untracked'
alias gsp='git_stash_pop'
alias gsa='git_stash_apply'
alias gsl='git stash list'
# Commit aliases
alias git_ci='git commit'
# Gitignore
alias gil='git_ignore_list'
alias gia='git_ignore_add'
# git add new files
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add $(git ls-files -o)'

########################################
# Meld called by git
git_meld() {
  meld "$2" "$5"
}

########################################
# Get git repo root directory
git_root() {
  git rev-parse --show-toplevel
}

# Check commit existenz
git_exists() {
  git rev-parse --verify "${1:-HEAD}" >/dev/null 2>&1
}

# Check if a repo has been modified
git_modified() {
  ! git diff-index --quiet HEAD --
}

########################################
# Push changes onto stash, revert changes
git_stash_push() {
  git stash save "stash-$(date +%Y%m%d-%H%M)${1:+_$1}"
}

# Push changes onto stash, does not revert anything
git_stash_save() {
  git_stash_push "$@" && git stash apply stash@{0} >/dev/null
}

# Pop change from stash
git_stash_pop() {
  git stash pop stash@{${1:-0}}
}

# Apply change from stash
git_stash_apply() {
  git stash apply stash@{${1:-0}}
}

# Show diff between stash and local copy
git_stash_diff() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git diff stash@{$STASH} "$@"
}

#Show stash content
git_stash_show() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git stash show -p stash@{$STASH} "$@"
}

# Aliases using stashes
alias git_stash_diffl='git_stash_diff --name-only'
alias git_export='git_stash_save'
alias git_import='git_stash_apply'
alias git_suspend='git_stash_push'
alias git_resume='git_stash_pop'
alias git_stash_list='git stash list'
alias git_stash_drop='git stash drop'

########################################
# Hard revert to a given CL or revert a file
git_revert() {
  if [ -f "$1" -o -f "$2" ]; then
    git checkout -- "$@"
  else
    local REV="${1:-HEAD}"; shift $(min 1 $#)
    git reset --hard "$REV" "$@"
  fi
}

# Soft revert to a given CL, won't change modified files
git_rollback() {
  local REV="${1:-HEAD}"; shift $(min 1 $#)
  git reset "$REV" "$@"
}

# Clean repo back to given CL
# remove unversionned files
git_clean() {
  # Confirmation
  if [ "$1" != "-y" ]; then
    echo -n "Remove unversioned files? (y/n): "
    local ANSWER; read ANSWER; [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && return 0
  fi
  # Clean repository
  git clean "$@"
}

########################################
# List files
git_ls() {
  git ls-tree -r ${1:-master} --name-only ${2:+| grep -F "$2"}
}

########################################
# Amend log
alias git_amend='git commit --amend'

# Amend author/committer names & emails
git_amend_names() {
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

########################################
# Purge a given file from history
git_purge_file() {
  local FILE="${1:?No path specified...}"
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch \"$FILE\"" \
    --prune-empty --tag-name-filter cat -- --all
}

# Forced garbage-collector (use after purge_file) 
git_purge_gc() {
  git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
  git reflog expire --expire=now --all
  git gc --prune=now
}

########################################
# Git history
git_history() {
  git log -p "$@"
}

# Git logs
git_log() {
  git log --name-only
}
git_logall() {
  git log --name-status
}
git_logstat() {
  git log --stat
}

########################################
# Git add gitignore
git_ignore_add() {
  grep "$1" .gitignore >/dev/null || echo "$1" >>.gitignore
}

# Git list gitignore
git_ignore_list() {
  git status -s --ignored 2>/dev/null || git clean -ndX
}

# Git ignore changes
git_ignore_changes() {
  git update-index --assume-unchanged "$@"
}
git_noignore_changes() {
  git update-index --no-assume-unchanged "$@"
}

########################################
# Show branch/url
git_url() {
  git config --get remote.${1:-origin}.url
}
git_branch() {
  git branch -a | grep -E '^\*' | cut -c 3-
}
