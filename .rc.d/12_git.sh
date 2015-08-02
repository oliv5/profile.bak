#!/bin/sh

# Editors
export GIT_EDITOR="${EDITOR:-vi}"
export GIT_PAGER="${PAGER:-less}"

########################################
# Status aliases
alias gt='git status -uno'
alias gtu='git status -u'
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
alias gls='git ls-files'
alias glm='git ls-files -m'
alias glu='git ls-files -u' # unmerged = in conflict
alias gld='git ls-files -d'
alias gln='git ls-files -o --exclude-standard'
alias gli='git ls-files -o -i --exclude-standard'
# Diff aliases
alias gdd='git_diff_all'
alias gdm='git_diffm_all'
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
alias gssa='git_stash_save_all'
alias gssu='git_stash_save_untracked'
alias gssl='git_stash_save_lazy'
alias gsp='git_stash_pop'
alias gsa='git_stash_apply'
alias gsl='git stash list'
alias gslc='git_stash_count'
alias gslf='git_stash_show'
alias gsla='git_stash_show_all'
alias gsv='git_stash_cat'
alias gsd='git_stash_diff'
alias gsdm='git_stash_diffm'
alias gsdl='git_stash_diffl'
alias gsf='git_stash_flush'
alias gsm='gsdm'
# Commit aliases
alias gci='git commit'
# Gitignore
alias gil='git_ignore_list'
alias gia='git_ignore_add'
# Add new files
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add $(git ls-files -o)'
# Logs/history aliases
alias git_history='git log -p'
alias git_log='git log --name-only'
alias git_logall='git log --name-status'
alias git_logstat='git log --stat'
# Tag aliases
alias gts='git tag'
alias gtl='git tag -l'
alias gtd='git tag -d'
alias gtc='git tag --contains'
# Annex
alias gas='git annex sync'
alias gal='git annex log'
alias gai='git annex info'
alias gag='git annex get'
alias gad='git annex drop'
alias gat='git annex status'
# Patch aliases
alias gpd='git diff -p'
alias gpc='git show'

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
git_diff_all() {
  git diff "$@" &&
  git diff --cached "$@"
}

# Svn diff staged/unstaged with meld
git_diffm() {
  git difftool -y -t meld "$@"
}
git_diffm_all() {
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
  #git ${1:+--work-tree="$1"} rev-parse --verify "HEAD" >/dev/null 2>&1
  git ${1:+--git-dir="$1"} rev-parse >/dev/null 2>&1
}

# Get current branch name
git_branch() {
  git rev-parse --abbrev-ref "${1:-HEAD}"
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
alias git_head='git_hash'
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
# Build git stash name
_git_stash_name() {
  echo "$(git_branch)-$(git_shorthash)-$(date +%Y%m%d-%H%M)${1:+_$1}"
}

# Push changes onto stash, revert changes
git_stash_save() {
  local STASH="$(_git_stash_name "$@")"; shift
  git stash save "$STASH" "$@"
}
git_stash_save_all() {
  local STASH="$(_git_stash_name "$@")"; shift
  git stash save --all "$STASH" "$@"
}
git_stash_save_untracked() {
  local STASH="$(_git_stash_name "$@")"; shift
  git stash save --untracked "$STASH" "$@"
}
git_stash_save_lazy() {
  local STASH="$(_git_stash_name "$@")"; shift
  git stash save --keep-index "$STASH" "$@"
}

# Push changes onto stash, does not revert anything
git_stash_push() {
  local STASH="$(_git_stash_name "$@")"; shift
  git update-ref -m "$STASH" refs/stash "$(git stash create)"
  #git stash create $STASH
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

# Show stash file list
git_stash_show() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git stash show stash@{$STASH} "$@"
}

# Show all stashes file list
git_stash_show_all() {
  local TOTAL=$(git stash list | wc -l)
  local START="${1:-0}"
  local END="${2:-$TOTAL}"
  shift $(min 2 $#)
  for IDX in $(seq $START $END); do
    echo "******************************"
    #echo "[git] stash number $IDX/$TOTAL"
    git stash list | awk 'NR=='$(($IDX+1))' {print $0; quit}'
    echo "------------"
    git_stash_show $IDX "$@"
    echo "------------"
    read -p "Press enter to go on..."
    echo "******************************"
  done
}

# Show stash file content
git_stash_cat() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git stash show -p stash@{$STASH} "$@"
}

# Flush the stash
git_stash_flush() {
  if ask_question "Flush the stash? (y/n): " y Y >/dev/null; then
    git stash clear
  fi
}

# Aliases using stashes
alias git_export='git_stash_save'
alias git_import='git_stash_apply'
alias git_suspend='git_stash_push'
alias git_resume='git_stash_pop'
alias git_stash_list='git stash list'
alias git_stash_drop='git stash drop'
alias git_stash_count='git stash list | wc -l'

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
  git clean -d --exclude=".*" "$@"
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
# https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History
# https://git-scm.com/docs/git-filter-branch
# Amend last commit
alias git_amend='git commit --amend'

# Amend author/committer names & emails
git_amend_names() {
  # Identify who/what the amend is about
  local AUTHOR_1="${1%%:*}"
  local AUTHOR_2="${1##*:}"
  local AUTHOR_EMAIL_1="${2%%:*}"
  local AUTHOR_EMAIL_2="${2##*:}"
  local AUTHOR_DATE_1="${3%%:*}"
  local AUTHOR_DATE_2="${3##*:}"
  local COMMITTER_1="${4%%:*}"
  local COMMITTER_2="${4##*:}"
  local COMMITTER_EMAIL_1="${5%%:*}"
  local COMMITTER_EMAIL_2="${5##*:}"
  local COMMITTER_DATE_1="${6%%:*}"
  local COMMITTER_DATE_2="${6##*:}"
  local REV="${7:-HEAD}"
  # Display what is going to be done
  echo "Replace author name '$AUTHOR_1' by '$AUTHOR_2'"
  echo "Replace author email '$AUTHOR_EMAIL_1' by '$AUTHOR_EMAIL_2'"
  echo "Replace author date '$AUTHOR_DATE_1' by '$AUTHOR_DATE_2'"
  echo "Replace committer name '$COMMITTER_1' by '$COMMITTER_2'"
  echo "Replace committer email '$COMMITTER_EMAIL_1' by '$COMMITTER_EMAIL_2'"
  echo "Replace committer date '$COMMITTER_DATE_1' by '$COMMITTER_DATE_2'"
  read -p "Press enter to go on..."
  # Define the replacement script
  local SCRIPT='
    [ ! -z "$AUTHOR_1" -a "$AUTHOR_1" = "$GIT_AUTHOR_NAME" ] && export GIT_AUTHOR_NAME="$AUTHOR_2"
    [ ! -z "$AUTHOR_EMAIL_1" -a "$AUTHOR_EMAIL_1" = "$GIT_AUTHOR_EMAIL" ] && export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL_2"
    [ ! -z "$AUTHOR_DATE_1" -a "$AUTHOR_DATE_1" = "$GIT_AUTHOR_DATE" ] && export GIT_AUTHOR_DATE="$AUTHOR_DATE_2"
    [ ! -z "$COMMITTER_1" -a "$COMMITTER_1" = "$GIT_COMMITTER_NAME" ] && export GIT_COMMITTER_NAME="$COMMITTER_2"
    [ ! -z "$COMMITTER_EMAIL_1" -a "$COMMITTER_EMAIL_1" = "$GIT_COMMITTER_EMAIL" ] && export GIT_COMMITTER_EMAIL="$COMMITTER_EMAIL_2"
    [ ! -z "$COMMITTER_DATE_1" -a "$COMMITTER_DATE_1" = "$GIT_COMMITTER_DATE" ] && export GIT_COMMITTER_DATE="$COMMITTER_DATE_2"
  '
  # Execute the script
  git filter-branch --env-filter "$SCRIPT" $REV
}

########################################
# Purge a given file from history
git_purge_file() {
  local FILE="${1:?No path specified...}"
  git filter-branch --force --index-filter \
    'git rm --cached --ignore-unmatch "$FILE"' \
    --prune-empty --tag-name-filter cat -- --all
}

# Purge commits from a given author
git_purge_author() {
  local NAME="${1:?No name specified...}"
  local REV="${2:-HEAD}"
  git filter-branch --commit-filter \
    'if [ "$GIT_AUTHOR_NAME" = "$NAME" ]; then skip_commit "$@"; else git commit-tree "$@"; fi' \
    $REV
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
