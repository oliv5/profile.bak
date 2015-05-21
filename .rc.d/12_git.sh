#!/bin/sh

# Editors
export GIT_EDITOR="${EDITOR:-vi}"
export GIT_PAGER="${PAGER:-less -Fs}"

########################################
# Status aliases
alias gt='git status -uno'
alias gm='git status --porcelain -b | awk "NR==1 || /^(M.|.M)/"'    # modified
alias ga='git status --porcelain -b | awk "NR==1 || /^A[ MD]/"'     # added
alias gd='git status --porcelain -b | awk "NR==1 || /^D[ M]/"'      # deleted
alias gr='git status --porcelain -b | awk "NR==1 || /^R[ MD]/"'     # renamed
alias gc='git status --porcelain -b | awk "NR==1 || /^C[ MD]/"'     # copied in index
alias gu='git status --porcelain -b | awk "NR==1 || /^[DAU][DAU]/"' # unmerged = conflict
alias gn='git status --porcelain -b | awk "NR==1 || /^\?\?/"'       # untracked = new
alias gi='git status --porcelain -b | awk "NR==1 || /^\!\!/"'       # ignored
alias gz='git status --porcelain -b | awk "NR==1 || /^[MARC] /"'    # in index
alias gs='git status --porcelain -b | awk "NR==1 || /^[^\?\?]/"'    # not untracked
# List aliases
alias gll='git ls-files'
alias glm='git ls-files -m'
alias glu='git ls-files -u' # unmerged = in conflict
alias gld='git ls-files -d'
alias gln='git ls-files -o --exclude-standard'
# Diff aliases
alias gdd='git_diff'
alias gdm='git_diffm'
alias gds='git diff stash'
# Merge aliases
alias gmm='git mergetool -y -t meld'
# Branch aliases
alias gbc='git branch'
alias gba='git branch -a'
alias gbr='git branch -r'
alias gbv='git branch -v'
# Stash aliases
alias gsc='git_stash_push'
alias gss='git_stash_save'
alias gsb='git_stash_save --include-untracked'
alias gsp='git_stash_pop'
alias gsa='git_stash_apply'
alias gsl='git stash list'
alias gsv='git_stash_show'
# Commit aliases
alias gci='git commit'
# Gitignore
alias gil='git_ignore_list'
alias gia='git_ignore_add'
# git add new files
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add $(git ls-files -o)'
# Git logs/history aliases
alias git_history='git log -p'
alias git_log='git log --name-only'
alias git_logall='git log --name-status'
alias git_logstat='git log --stat'
# Annex
alias gas='git annex sync'
alias gal='git annex log'
alias gai='git annex info'
alias gag='git annex get'
alias gad='git annex drop'
alias gast='git annex status'

########################################
# git wrapper
git() {
  if [ "$1" == "annex" -a ! -z "$(command git config --get vcsh.vcsh)" ]; then
    if [ "$(command git config --get annex.direct)" = "true" -o "$2" = "direct" ]; then
      echo "git annex in direct mode is not compatible with VCSH repositories..."
      return 1
    fi
  fi
  command git "$@"
}

########################################
# Git status for scripts
git_st() {
  git status -z | awk 'BEGIN{RS="\0"; ORS="\0"}/'"${1:-^[^\?\?]}"'/{print substr($0,4)}'
}

########################################
# Meld called by git
git_meld() {
  meld "$2" "$5"
}

########################################
# Svn diff staged/unstaged
git_diff() {
  git diff "$@" &&
  git diff --cached "$@"
}

# Svn diff staged/unstaged with meld
git_diffm() {
  git difftool -y -t meld "$@" &&
  git difftool --cached -y -t meld "$@"
}

########################################
# Get git repo root directory
git_root() {
  git rev-parse --show-toplevel
}

# Check repo existenz
git_exists() {
  git rev-parse --verify "${1:-HEAD}" >/dev/null 2>&1
}

# Check if a repo has been modified
git_modified() {
  ! git diff-index --quiet HEAD --
}

# Check annex existenz
git_annex_exists() {
  git config --get annex.version >/dev/null 2>&1
}

# Check if an annex has been modified
git_annex_modified() {
  test ! -z "$(git annex status)"
}

########################################
# Get hash
git_hash() {
  git rev-parse "${@:-HEAD}"
}
git_allhash() {
  git rev-list "${@:-HEAD}"
}

# Get short hash
git_shorthash() {
  git_hash "$@" | cut -c 1-7
}
git_allshorthash() {
  git_allhash "$@" | cut -c 1-7
}

########################################
# Push changes onto stash, revert changes
git_stash_save() {
  git stash save "stash-$(date +%Y%m%d-%H%M)${1:+_$1}"
}

# Push changes onto stash, does not revert anything
git_stash_push() {
  local STASH="stash-$(date +%Y%m%d-%H%M)${1:+_$1}"
  git update-ref -m "$STASH" refs/stash "$(git stash create \"$STASH\")"
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
git_stash_diffm() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git_diffm stash@{$STASH} "$@" 
}
git_stash_diffl() {
  git_stash_diff "${@:-0}" --name-only
}

#Show stash content
git_stash_show() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git stash show -p stash@{$STASH} "$@"
}

# Aliases using stashes
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
    ! ask_question "Remove unversioned files? (y/n) " y Y >/dev/null && return 0
  else
    shift
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
# Merge 1 repo as a subtree of current repo
git_subtree_add() {
  local REPO="${1:?No repository specified}"
  local PREFIX="${2:+--prefix="$2"}"
  local REF="${3:-master}"
  git subtree add $PREFIX "$REPO" "$REF"
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
# Git add gitignore
git_ignore_add() {
  grep "$1" .gitignore >/dev/null || echo "$1" >>.gitignore
}

# Git list gitignore
git_ignore_list() {
  git status -s --ignored 2>/dev/null || git clean -ndX
}

# Git ignore changes
alias git_ignore_changes='git update-index --assume-unchanged'
alias git_noignore_changes='git update-index --no-assume-unchanged'

########################################
# Show branch/url
git_url() {
  git config --get remote.${1:-origin}.url
}
git_branch() {
  git branch -a | grep -E '^\*' | cut -c 3-
}

########################################
# Remove things
alias git_rm_tracking_branch='git branch -dr'
alias git_rm_tracking_branch2='git fetch -p'
alias git_rm_remote_branch='push origin -d'
alias git_rm_branch='git branch -d'
