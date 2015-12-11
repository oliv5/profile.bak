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
#alias gc='git status --porcelain -b | awk "NR==1 || /^C[ MD]/"'     # copied in index
alias gc='git status --porcelain -b | awk "NR==1 || /^[DAU][DAU]/"' # unmerged = conflict
alias gu='git status --porcelain -b | awk "NR==1 || /^\?\?/"'       # untracked = new
alias gi='git status --porcelain -b | awk "NR==1 || /^\!\!/"'       # ignored
alias gz='git status --porcelain -b | awk "NR==1 || /^[MARC] /"'    # in index
alias gs='git status --porcelain -b | awk "NR==1 || /^[^\?\?]/"'    # not untracked
alias gstatus='git status'
# List aliases
alias gll='git ls-files'
alias gls='git ls-files'
alias glm='git ls-files -m'
alias glu='git ls-files -u' # unmerged = in conflict
alias gld='git ls-files -d'
alias gln='git ls-files -o --exclude-standard'
alias gli='git ls-files -o -i --exclude-standard'
# Diff aliases
alias gdd='git diff'
alias gdm='git_diffm'
alias gdda='git_diff_all'
alias gdma='git_diffm_all'
alias gds='git diff stash'
alias gdiff='git diff'
# Merge aliases
alias gmm='git mergetool -y'
alias gmerge='gmm'
# Branch aliases
alias gba='git branch -a'
alias gbv='git branch -v'   # verbose list branch
alias gbva='git branch -va' # verbose list branch
alias gbd='git branch -d'   # branch delete
alias gbdf='git branch -D'  # forced branch delete
alias gbr='git branch -r'   # list tracking
alias gbrd='git branch -rd' # remove tracking
alias gbranch='git branch'
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
alias gsdd='git_stash_diff'
alias gsdm='git_stash_diffm'
alias gsdl='git_stash_diffl'
alias gsf='git_stash_flush'
alias gsb='git_stash_backup'
alias gsrm='git_stash_drop'
alias gsm='gsdm'
alias gstash='git stash'
# Gitignore aliases
alias gil='git_ignore_list'
alias gia='git_ignore_add'
# Add files aliases
alias gad='git add'
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add -u'
alias gadd='git add'
# Commit aliases
alias gci='git commit'
alias gcm='git commit -m'
alias gcim='git commit -m'
alias gcam='git commit -am'
alias gcommit='git commit'
# Misc aliases
alias grm='git rm'
alias gmv='git mv'
# Logs/history aliases
alias glogh='git log -p'
alias glogn='git log --name-only'
alias gloga='git log --name-status'
alias glogs='git log --stat'
alias glog='git log'
# Tag aliases
alias gts='git tag'
alias gtl='git tag -l'
alias gtd='git tag -d'
alias gtc='git tag --contains'
alias gtag='git tag'
# Annex aliases
alias gat='git annex status'
alias gal='git annex list'
alias gas='git annex sync'
alias gag='git annex get'
alias gac='git annex copy'
alias gad='git annex drop'
alias gai='git annex info'
alias gannex='git annex'
# Patch aliases
alias gpd='git diff -p'
alias gpc='git show'
# Subtree aliases
alias gsta='git_subtree_add'
alias gstu='git_subtree_update'
# Git grep aliases
alias ggg='git grep -n'
alias iggg='git grep -ni'
alias ggrep='git grep'
# Checkout aliases
alias gco='git checkout'
alias gcheckout='git checkout'
# Reset aliases
alias gre='git reset'
alias grh='git reset HEAD'
alias greset='git reset'
# Rebase aliases
alias grb='git rebase'
alias grbi='git rebase -i'
alias grebase='git rebase'
# Pull/push aliases
alias gps='git push'
alias gpush='git push'
alias gpl='git pull'
alias gpull='git pull'
alias gpr='git pull --rebase'
# Config aliases
alias gcl='git config -l'
alias gcll='git config -l --local'
alias gclg='git config -l --global'
alias gcls='git config -l --system'
alias gcfl='git config --local'
alias gcfg='git config --global'
alias gcfs='git config --system'
alias gcbt='git config --set core.bare true'
alias gcbf='git config --set core.bare false'
alias gconfig='git config'

########################################
# Env setup
git_setup() {
  git config --global diff.tool meld
  git config --global merge.tool mymerge
  git config --global merge.conflictstyle diff3
  git config --global mergetool.mymerge.cmd \
    'meld --diff "$BASE" "$LOCAL" --diff "$BASE" "$REMOTE" --diff "$LOCAL" "$MERGED" "$REMOTE"'
  git config --global rerere.enabled 1
  git config --global core.excludesfile '~/.gitignore'
}

########################################
# git wrapper
git() {
  if [ "$1" = "annex" -a ! -z "$(command git config --get vcsh.vcsh)" ]; then
    if [ "$(command git config --get annex.direct)" = "true" -o "$2" = "direct" ]; then
      echo "git annex in direct mode is not compatible with VCSH repositories..."
      return 1
    fi
  fi
  command git "$@"
}

########################################
# Check repo exists
git_exists() {
  #git ${1:+--work-tree="$1"} rev-parse --verify "HEAD" >/dev/null 2>&1
  git ${1:+--git-dir="$1"} rev-parse --verify HEAD >/dev/null 2>&1
}

# Check bare repo attribute
git_bare() {
  [ "$(git ${1:+--git-dir="$1"} config --get core.bare)" = "true" ]
}

# Get git worktree directory
git_worktree() {
  git ${1:+--git-dir="$1"} rev-parse --show-toplevel
}

# Get git directory (alias git-dir)
git_dir() {
  readlink -f "${GIT_DIR:-$(git rev-parse --git-dir)}"
}

# Get git exec-path
git_exp() {
  git --exec-path
}

# Get git-dir basename
git_repo() {
  local DIR="$(git_dir)"
  [ "${DIR##*/}" = ".git" ] && 
    basename "${DIR%/*}" .git || 
    basename "$DIR" .git
}

# Get current branch name
git_branch() {
  git ${2:+--git-dir="$2"} rev-parse --abbrev-ref "${1:-HEAD}"
  #git branch -a | grep -E '^\*' | cut -c 3-
}

# Get current url
git_url() {
  git ${2:+--git-dir="$2"} config --get remote.${1:-origin}.url
}

# Check if a repo has been modified
git_modified() {
  ! git ${1:+--git-dir="$1"} diff-index --quiet HEAD --
}

# Git status for scripts
git_st() {
  git status -s | awk '/^[\? ]?'$1'[\? ]?/ {print "\""$2"\""}'
}
git_stx() {
  git status -z | awk 'BEGIN{RS="\0"; ORS="\0"}/'"^[\? ]?$1"'/{print substr($0,4)}'
}

# Get local branches names
git_branches() {
  git ${2:+--git-dir="$2"} for-each-ref --format='%(refname:short)' refs/heads/ | xargs echo
}

# Get remote names
git_remotes() {
  git ${2:+--git-dir="$2"} remote | xargs echo
}

# Get git backup name
git_name() {
  echo "$(git_repo).${1:+$1.}$(uname -n).$(git_branch | tr '/' '_').$(date +%Y%m%d-%H%M%S).$(git_shorthash)"
}

# Check a set of commands exist
git_cmd() {
  local EXECPATH="$(git_exp)"
  for CMD; do
    [ -x "${EXECPATH}/git-${CMD}" ] || return 1
  done
  return 0
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
  git_hash "$@" | cut -c 1-8
}
git_allshorthash() {
  git_allhash "$@" | cut -c 1-8
}

########################################
# Repo init
git_init() {
  local DIR="$1"
  shift 2>/dev/null
  mkdir -p "$DIR"
  cd "$DIR" || return 1
  [ ! -d ".git" ] && git init
  for ARGS; do
    set -- $ARGS
    git remote add "$@"
  done
}

# Repo clone
git_clone() {
  local URL="${1:?No URL specified}"
  local REMOTE="${2:-origin}"
  local BRANCH="${3:-master}"
  local DIR="$(basename "$URL" .git)"
  shift 3 2>/dev/null
  git clone "$URL" "$DIR" || break
  git --git-dir="$DIR/.git" remote rename origin "$REMOTE"
  git --git-dir="$DIR/.git" checkout "$BRANCH"
  for ARGS; do
    set -- $ARGS
    git remote add "$@"
  done
}

# Wrapper: vcsh run
# Overwritten by vcsh main script
vcsh_run() {
  eval "$@"
}

# Wrapper: git annex direct mode
# Overwritten by annex main script
annex_direct() {
  false
}

# Batch pull existing remote/branches
git_pull() {
  git_exists || return 1
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  local CURRENT="$(git_branch)"
  if annex_direct; then
    # Note: git annex repos in direct mode
    # are not compatible with vcsh
    git annex sync
  else
    vcsh_run "
      end() {
        git checkout -q \"$CURRENT\"
        if [ -n \"\$STASH\" ]; then
          git stash apply -q --index \"\$STASH\"
        fi
        trap - INT TERM EXIT
      }
      set +e
      trap 'end' INT TERM EXIT
      STASH=\"\$(git stash create 2>/dev/null)\"
      if [ -n \"\$STASH\" ]; then
        git reset --hard HEAD -q --
      fi
      for BRANCH in $BRANCHES; do
        git checkout \"\$BRANCH\" >/dev/null|| continue
        for REMOTE in $REMOTES; do
          if git branch -r | grep -- \"\$REMOTE/\$BRANCH\" >/dev/null; then
            if [ -x \"\$(git --exec-path)/git-pull\" ]; then
              git pull --rebase \"\$REMOTE\" \"\$BRANCH\"
            else
              git fetch \"\$REMOTE\" \"\$BRANCH\" &&
              git merge --ff-only \"\$REMOTE/\$BRANCH\"
            fi
          fi
        done
      done
      end
    "
  fi
}

# Batch push existing remote/branches
alias git_push='git_push_existing'
git_push_existing() {
  git_exists || return 1
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  for REMOTE in $REMOTES; do
    for BRANCH in $BRANCHES; do
      if git branch -r | grep -- "$REMOTE/$BRANCH" >/dev/null; then
        echo -n "Push $REMOTE/$BRANCH : "
        git push "$REMOTE" "$BRANCH"
      fi
    done
  done
}

# Batch push all local branches to remotes
git_push_all() {
  git_exists || return 1
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  for REMOTE in $REMOTES; do
    for BRANCH in $BRANCHES; do
      echo -n "Push $REMOTE/$BRANCH : "
      git push "$REMOTE" "$BRANCH"
    done
  done
}

# Create a bundle
git_bundle() {
  local DIR="${1:-$(git_dir)}"
  if [ -d "$DIR" ]; then
    DIR="${1:-$DIR/bundle}"
    local BUNDLE="$DIR/${2:-$(git_name "bundle").git}"
    local GPG_RECIPIENT="$3"
    echo "Git bundle into $BUNDLE"
    git bundle create "$BUNDLE" --all --tags --remotes
    if [ ! -z "$GPG_RECIPIENT" ]; then
      gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" "${BUNDLE}" && 
        (shred -fu "${BUNDLE}" || wipe -f -- "${BUNDLE}" || rm -- "${BUNDLE}")
    fi
    ls -l "${BUNDLE}"*
  else
    echo "Target directory '$DIR' does not exists."
    echo "Skip bundle creation..."
  fi
}

########################################
# Svn diff staged/unstaged
git_diff_all() {
  git diff "$@" 2>/dev/null
  git diff --cached "$@"
}

# Svn diff staged/unstaged changes
git_diffm() {
  git difftool -y "$@"
}
git_diffm_all() {
  git difftool -y "$@" 2>/dev/null
  git difftool --cached -y "$@"
}

########################################

# Push changes onto stash, revert changes
git_stash_save() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  git stash save "$STASH" "$@"
}
git_stash_save_all() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  git stash save --all "$STASH" "$@"
}
git_stash_save_untracked() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  git stash save --untracked "$STASH" "$@"
}
git_stash_save_lazy() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  git stash save --keep-index "$STASH" "$@"
}

# Push changes onto stash, does not revert anything
git_stash_push() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  local REF="$(git stash create)"
  git stash store -m "$STASH" "$REF" 2>/dev/null || 
    git update-ref -m "$STASH" refs/stash "$REF"
}

# Pop change from stash
git_stash_pop() {
  git stash pop "stash@{${1:-0}}"
}

# Apply change from stash
git_stash_apply() {
  git stash apply "stash@{${1:-0}}"
}

# Show diff between stash and local copy
git_stash_diff() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git diff "stash@{$STASH}" "$@"
}
git_stash_diffm() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git_diffm "stash@{$STASH}" "$@" 
}
git_stash_diffl() {
  git_stash_diff "${@:-0}" --name-only
}

# Show stash file list
git_stash_show() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git stash show "stash@{$STASH}" "$@"
}

# Show all stashes file list
git_stash_show_all() {
  local TOTAL=$(git stash list | wc -l)
  local START="${1:-0}"
  local END="${2:-$TOTAL}"
  shift 2 2>/dev/null
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
  local STASH="${1:-0}"; shift 2>/dev/null
  git stash show -p "stash@{$STASH}" "$@"
}

# Drop a stash
git_stash_drop() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git stash drop "stash@{$STASH}" "$@"
}

# Flush the stash
git_stash_flush() {
  if ask_question "Flush the stash? (y/n): " y Y >/dev/null; then
    git stash clear
  fi
}

# Backup stashes in .git/backup
#git stash list --pretty=format:"%h %gd %ci" | awk '{gsub(/-/,"",$3); gsub(/:/,"",$4); print "stash{" $3 "-" $4 "}_" $1}'
git_stash_backup() {
  git_exists || return 1
  local DST="$(git_dir)/backup"
  mkdir -p "$DST"
  ( IFS=$'\n'
    #for DESCR in $(git stash list --pretty=format:"%h %gd %ci"); do
    #  local NAME="$(echo $DESCR | awk '{gsub(/-/,"",$3); gsub(/:/,"",$4); print "stash{" $3 "-" $4 "}_" $1}')"
    for DESCR in $(git stash list --oneline); do
      local NAME="$(echo $DESCR | sed 's/^.*: // ; s/[^0-9a-zA-Z._:]/_/g')"
      local HASH="$(echo $DESCR | awk '{print $1}')"
      local FILE="$DST/stash_${HASH}_${NAME}.gz"
      if [ ! -e "$FILE" ]; then
        echo "Backup $HASH in $FILE"
        git stash show -p "$HASH" "$@" | gzip --best > "$FILE"
      fi
    done
  )
}

# Aliases using stashes
alias git_suspend='git_stash_save'
alias git_resume='git_stash_pop'
alias git_stash_list='git stash list'
alias git_stash_count='git stash list | wc -l'

########################################
# Revert files to a given ref
git_revert() {
  local REV="HEAD"
  if [ ! -f "$1" ]; then
    REV="$1"
    shift 2>/dev/null
  fi
  git reset "$REV" -- "$@"
  git checkout "$REV" -- "$@"
}

# Hard reset files to a given rev
alias git_reset='git reset --hard'

# Soft revert to a given CL, won't change modified files
git_rollback() {
  local REV="${1:-HEAD}"; shift 2>/dev/null
  git reset "$REV" "$@"
}

# Clean repo back to given CL
# remove unversionned files
git_clean() {
  git_exists || return 1
  # Confirmation
  if [ "$1" != "-y" ]; then
    ! ask_question "Remove unversioned files? (y/n) " y Y >/dev/null && return 0
  fi
  shift
  # Backup
  local DST="$(git_dir)/clean"
  mkdir -p "$DST"
  git_stx '??' | xargs -0 7z a "$DST/clean.$(git_name).7z"
  # Clean repository
  git clean -d --exclude=".*" "$@"
}

########################################
# List local files
git_ls() {
  git ls-tree -r ${1:-$(git_branch)} --name-only ${2:+| grep -F "$2"}
}

# List files in commit
git_list() {
  #git show --pretty="format:" --name-only "${@:-HEAD}"
  git diff-tree --no-commit-id --name-only -r "${@:-HEAD}"
}

# Cat a file
git_cat() {
  #git show ${1:-HEAD}:"$2"
  local REV="${1:-HEAD}"
  shift 2>/dev/null
  for FILE in "${@:-}"; do
    git show ${REV}:"$FILE"
  done
}

########################################
# Subtrees
# See https://developer.atlassian.com/blog/2015/05/the-power-of-git-subtree/
# Merge 1 repo as a subtree of current repo
git_subtree_add() {
  local REPO="${1:?No remote repository specified}"
  local PREFIX="${2:?No local destination specified}"
  local REF="${3:-master}"
  git subtree add --prefix="$PREFIX" "$REPO" "$REF" --squash
}

# Merge 1 repo as a subtree of current repo
git_subtree_update() {
  local REPO="${1:?No remote repository specified}"
  local PREFIX="${2:?No local destination specified}"
  local REF="${3:-master}"
  git subtree pull --prefix="$PREFIX" "$REPO" "$REF" --squash
}

########################################
# https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History
# https://git-scm.com/docs/git-filter-branch
# Amend last commit
alias git_amend='git commit --amend'

# Amend author/committer names & emails
git_amend_names() {
 # Run in a subshell because we need to export lots of variables
(
  # Identify who/what the amend is about
  export AUTHOR_1="${1%%:*}"
  export AUTHOR_2="${1##*:}"
  export AUTHOR_EMAIL_1="${2%%:*}"
  export AUTHOR_EMAIL_2="${2##*:}"
  export AUTHOR_DATE_1="${3%%:*}"
  export AUTHOR_DATE_2="${3##*:}"
  export COMMITTER_1="${4%%:*}"
  export COMMITTER_2="${4##*:}"
  export COMMITTER_EMAIL_1="${5%%:*}"
  export COMMITTER_EMAIL_2="${5##*:}"
  export COMMITTER_DATE_1="${6%%:*}"
  export COMMITTER_DATE_2="${6##*:}"
  local REV="${7:-HEAD}"
  # Display what is going to be done
  [ ! -z "$AUTHOR_1" ] && echo "Replace author name '$AUTHOR_1' by '$AUTHOR_2'"
  [ ! -z "$AUTHOR_EMAIL_1" ] && echo "Replace author email '$AUTHOR_EMAIL_1' by '$AUTHOR_EMAIL_2'"
  [ ! -z "$AUTHOR_DATE_1" ] && echo "Replace author date '$AUTHOR_DATE_1' by '$AUTHOR_DATE_2'"
  [ ! -z "$COMMITTER_1" ] && echo "Replace committer name '$COMMITTER_1' by '$COMMITTER_2'"
  [ ! -z "$COMMITTER_EMAIL_1" ] && echo "Replace committer email '$COMMITTER_EMAIL_1' by '$COMMITTER_EMAIL_2'"
  [ ! -z "$COMMITTER_DATE_1" ] && echo "Replace committer date '$COMMITTER_DATE_1' by '$COMMITTER_DATE_2'"
  read -p "Press enter to go on..."
  # Define the replacement script
  local SCRIPT='
    STATUS="no change"
    if [ ! -z "$AUTHOR_1" -a "$AUTHOR_1" = "$GIT_AUTHOR_NAME" ]; then export GIT_AUTHOR_NAME="$AUTHOR_2"; STATUS="updated"; fi
    if [ ! -z "$AUTHOR_EMAIL_1" -a "$AUTHOR_EMAIL_1" = "$GIT_AUTHOR_EMAIL" ]; then export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL_2"; STATUS="updated"; fi
    if [ ! -z "$AUTHOR_DATE_1" -a "$AUTHOR_DATE_1" = "$GIT_AUTHOR_DATE" ]; then export GIT_AUTHOR_DATE="$AUTHOR_DATE_2"; STATUS="updated"; fi
    if [ ! -z "$COMMITTER_1" -a "$COMMITTER_1" = "$GIT_COMMITTER_NAME" ]; then export GIT_COMMITTER_NAME="$COMMITTER_2"; STATUS="updated"; fi
    if [ ! -z "$COMMITTER_EMAIL_1" -a "$COMMITTER_EMAIL_1" = "$GIT_COMMITTER_EMAIL" ]; then export GIT_COMMITTER_EMAIL="$COMMITTER_EMAIL_2"; STATUS="updated"; fi
    if [ ! -z "$COMMITTER_DATE_1" -a "$COMMITTER_DATE_1" = "$GIT_COMMITTER_DATE" ]; then export GIT_COMMITTER_DATE="$COMMITTER_DATE_2"; STATUS="updated"; fi
    echo " => $STATUS"
  '
  # Execute the script
  git filter-branch -f --env-filter "$SCRIPT" $REV
)
}

########################################
# Purge a given file from history
git_purge_file() {
  local FILE="${1:?No path specified...}"
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch '$FILE'" \
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

# Truncate history from a given commit
# Warning: it rewrites everything
git_truncate() {
  echo "${1:?No commit specified}" > "$(git_dir)/info/grafts"
  echo "Check the repo history. Go on ? (enter/ctrl-c)"
  read
  git filter-branch --tag-name-filter cat -- --all
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
# Remove branches
alias git_rm_branch='git branch -d'
alias git_rm_branch_remote='git push :'
alias git_rm_tracking='git branch -dr'
alias git_rm_tracking_old='git fetch -p'

# Create a new branch from current one
# with a single commit in it
git_split() {
  git branch "${1:?No branch name specified}" $(echo "${2:-Initial commit.}" | git commit-tree HEAD^{tree})
}

########################################
# https://stackoverflow.com/questions/4479960/git-checkout-to-a-specific-folder
# Export the whole repo
git_backup() {
  local DST="${1:-$(git_dir)/backup/backup.$(git_name)}"
  shift
  # The last '/' is important
  git checkout-index -a -f --prefix="$DST/" "$@"
  7z a "${DST}.7z" "$DST" && rm -rf "$DST"
}

# Export a directory
git_backupdir() {
  local SRC="${1:?No input directory specified}"
  shift
  find "$SRC" -print0 | git_backup "$@" -f -z --stdin
}

########################################
# Store repo metadata
git_meta_store() {
  git-cache-meta --store && 
    git add "$(git_dir)/git_cache_meta" -f
}

########################################
# Display commit graph
git_graph() {
  git log --graph --pretty=format:'%C(blue)%h - %C(bold cyan)%an %C(bold green)(%ar)%C(bold yellow)%d%n''          %C(bold red)%s%C(reset)%n''%w(0,14,14)%b' "$@"
}

# Search for a string in a commit
git_search() {
  git log -S "${1:?nothing to search for...}" --source --all
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
