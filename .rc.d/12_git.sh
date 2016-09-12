#!/bin/sh

# Editors
export GIT_EDITOR="${EDITOR:-vi}"
export GIT_PAGER="${PAGER:-less}"

########################################
# Status aliases
alias gt='git status -uno'
alias gtu='gstu'
alias gst='git_st'
alias gstm='git status --porcelain -b | awk "NR==1 || /^(M.|.M)/"'    # modified
alias gsta='git status --porcelain -b | awk "NR==1 || /^A[ MD]/"'     # added
alias gstd='git status --porcelain -b | awk "NR==1 || /^D[ M]|^ D/"'  # deleted
alias gstr='git status --porcelain -b | awk "NR==1 || /^R[ MD]/"'     # renamed
#alias gstc='git status --porcelain -b | awk "NR==1 || /^C[ MD]/"'     # copied in index
alias gstc='git status --porcelain -b | awk "NR==1 || /^[DAU][DAU]/"' # unmerged = conflict
alias gstu='git status --porcelain -b | awk "NR==1 || /^\?\?/"'       # untracked = new
alias gsti='git status --porcelain -b | awk "NR==1 || /^\!\!/"'       # ignored
alias gstz='git status --porcelain -b | awk "NR==1 || /^[MARC] /"'    # in index
alias gsts='git status --porcelain -b | awk "NR==1 || /^[^\?\?]/"'    # not untracked
alias gstx='git_stx'
alias gstxm='git_stx "^(M.|.M)"'    # modified
alias gstxa='git_stx "^A[ MD]"'     # added
alias gstxd='git_stx "^D[ M]|^ D"'  # deleted
alias gstxr='git_stx "^R[ MD]"'     # renamed
#alias gstxc='git_stx "^C[ MD]"'     # copied in index
alias gstxc='git_stx "^[DAU][DAU]"' # unmerged = conflict
alias gstxu='git_stx "^\?\?"'       # untracked = new
alias gstxi='git_stx "^\!\!"'       # ignored
alias gstxz='git_stx "^[MARC] "'    # in index
alias gstxs='git_stx "^[^\?\?]"'    # not untracked# List aliases
# List files
alias gll='git ls-files'
alias gls='git ls-files'
alias glm='git ls-files -m'
alias glu='git ls-files -u' # unmerged = in conflict
alias gld='git ls-files -d'
alias gln='git ls-files -o --exclude-standard'
alias gli='git ls-files -o -i --exclude-standard'
# Diff aliases
alias gd='git diff'
alias gdd='git diff'
alias gdm='git difftool -y'
alias gda='git_diff_all'
alias gdda='git_diff_all'
alias gdma='git_diffm_all'
alias gdc='git diff --cached'
alias gddc='git diff --cached'
alias gdmc='git difftool -y --cached'
alias gdl='git diff --name-status'
alias gdls='git diff --name-status'
alias gds='git diff stash'
# Merge aliases
alias gmm='git mergetool -y'
# Branch aliases
alias gba='git branch -a'   # list all
alias gbl='git branch -l'   # list local
alias gbv='git branch -v'   # verbose list local
alias gbva='git branch -va' # verbose list all
alias gbav='git branch -va' # verbose list all
alias gbm='git branch --merged'    # list merged branches
alias gbM='git branch --no-merged' # list unmerged branches
alias gbr='git branch -r'   # list remote
alias gbd='git branch -d'   # delete branch (merged only)
alias gbD='git branch -D'   # delete branch (any)
alias gbdr='git branch -rd' # remove remote branch (merged only)
alias gbDr='git push :'     # remove remote branch (any)
alias gbdro='git fetch -p'  # remote all old remotes
alias gbu='git branch --set-upstream-to '  # set branch upstream
alias gb='git branch'
# Stash aliases
alias gsc='git_stash_create'
alias gss='git_stash_save'
alias gssa='git_stash_save_all'
alias gssu='git_stash_save_untracked'
alias gssl='git_stash_save_lazy'
alias gsp='git_stash_pop'
alias gsa='git_stash_apply'
alias gsab='git_stash_apply_branch'
alias gsl='git stash list'
alias gslc='git stash list | wc -l'
alias gsf='git_stash_file'
alias gsfa='git_stash_file_all'
alias gsfc='git_stash_cat'
alias gsd='git_stash_diff'
alias gsdd='git_stash_diff'
alias gsdm='git_stash_diffm'
alias gsdl='git_stash_diffl'
alias gsb='git_stash_backup'
alias gsrm='git_stash_drop'
alias gsm='gsdm'
alias git_suspend='git_stash_save'
alias git_resume='git_stash_pop'
# Gitignore aliases
alias gil='git_ignore_list'
alias gia='git_ignore_add'
# Commit aliases
alias gci='git commit'
alias gcm='git commit -m'
alias gcim='git commit -m'
alias gcam='git commit -am'
# Misc aliases
alias grm='git rm'
alias grmu='git clean -fn'
alias gmv='git mv'
# Logs/history aliases
alias gln='git log -n'
alias gl1='git log -n 1'
alias gl2='git log -n 2'
alias glh='git log -p'
alias glo='git log --name-only'
alias gla='git log --name-status'
alias gls='git log --stat'
alias glog='git log'
alias git_history='git log -p'
# Tag aliases
alias gta='git tag -a'
alias gtl='git tag -l'
alias gtd='git tag -d'
alias gtc='git_tag_create'
alias gtf='git tag --contains'
alias gtls='git log --tags --simplify-by-decoration --pretty="format:%ai %d"'
alias gtda='git tag -l | xargs git tag -d'
alias gtdl='git tag -l | xargs git tag -d; git fetch'
alias gtg='git tag'
alias gtag='git tag'
# Add aliases
alias ga='git add'
alias gan='git add $(git ls-files -o --exclude-standard)'
alias gau='git add -u'
# Annex aliases
alias gana='git annex add'
alias gant='git annex status'
alias ganst='annex_st'
alias ganl='git annex list'
alias ganlc='git annex find | wc -l'
alias ganf='git annex find'
alias ganfc='git annex find | wc -l'
alias gans='git annex sync'
alias gang='git annex get'
alias ganc='git annex copy'
alias ganca='git annex copy --all'
alias gancf='git annex copy --fast'
alias ganct='git annex copy --to'
alias gancat='git annex copy --all --to'
alias gancft='git annex copy --fast --to'
alias gancf='git annex copy --from'
alias gancaf='git annex copy --all --from'
alias gancff='git annex copy --fast --from'
alias gand='git annex drop'
alias gandd='git annex forget --drop-dead'
alias gani='git annex info'
alias gannex='git annex'
# Patch aliases
alias gpc='git show'
alias gpd='git diff -p'
alias gpm='git format-patch -1'
alias gps='git_stash_cat'
alias gpa='git apply'
# Subtree aliases
alias gsbta='git_subtree_add'
alias gsbtu='git_subtree_update'
# Git grep aliases
alias ggg='git grep -n'
alias iggg='git grep -ni'
alias ggrep='git grep'
# Checkout aliases
alias gco='git checkout'
# Reset aliases
alias gre='git reset'
alias greh='git reset --hard'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias git_rollback='git reset'
# Revert a commit by making a new one
# Use -m 1,2... to select the wanted
# parent branch of a merge commit
alias git_revert='git revert'
# Amend last commit
alias git_amend='git commit --amend'
# Rebase aliases
alias grb='git rebase'
alias grbi='git rebase -i'
# Fetch/pull/push aliases
alias gps='git_push'
alias gpl='git_pull'
alias gpr='git pull --rebase'
alias gup='git pull --rebase --autostash'
alias gupa='git_pull_all'
alias gfe='git fetch'
alias gfa='git fetch --all'
# Config aliases
alias gcl='git config -l'
alias gcg='git config --get'
alias gcs='git config --set'
alias gcfg='git config'
alias gcfgl='git config -l'
alias gcfgg='git config -g'
alias gconfig='git config'
# Git ignore changes
alias git_ignore_changes='git update-index --assume-unchanged'
alias git_noignore_changes='git update-index --no-assume-unchanged'

########################################
# Dependencies

# Wrapper: vcsh run
# Overwritten by vcsh main script
command -v "vcsh_run" >/dev/null 2>&1 ||
vcsh_run() {
  eval "$@"
}

# Wrapper: git annex direct mode
# Overwritten by annex main script
command -v "annex_direct" >/dev/null 2>&1 ||
annex_direct() {
  false
}

# Ask question
command -v "ask_question" >/dev/null 2>&1 ||
ask_question() {
  local ANSWER
  echo -n "$1 " >&2
  read ANSWER
  echo "$ANSWER" >&2
  shift
  for ARG; do
    [ "$ARG" = "$ANSWER" ] && return 0
  done
  return 1
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
# Env setup
git_setup() {
  git config --global diff.tool meld
  git config --global merge.tool mymerge
  git config --global merge.conflictstyle diff3
  git config --global mergetool.mymerge.cmd \
    'meld --diff "$BASE" "$LOCAL" --diff "$BASE" "$REMOTE" --diff "$LOCAL" "$MERGED" "$REMOTE"'
  git config --global mergetool.mymerge.trustExitCode true
  git config --global rerere.enabled true
  git config --global core.excludesfile '~/.gitignore'
}

########################################
# Get git version
git_version() {
  local VERSION="${1:-$(git --version | cut -d' ' -f 3)}"
  expr $(echo $VERSION | awk -F'.' '{printf "%.d%.2d%.2d%.2d",$1,$2,$3,$4}')
}

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
# Hide errors when ref is unknown
git_branch() {
  git ${2:+--git-dir="$2"} rev-parse --abbrev-ref "${1:-HEAD}" 2>/dev/null
  #git branch -a | grep -E '^\*' | cut -c 3-
}

# Get all local branches
git_branches() {
  git ${1:+--git-dir="$1"} for-each-ref --shell refs/heads/ --format='%(refname:short)'
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
git_branches_info() {
  for branch in $(git branch -r $@ | grep -v HEAD); do 
    echo -e $(git show --format="%ci %cr %an" $branch | head -n 1) \\t$branch
  done | sort -r
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

# Check a remote repo exists
git_ping() {
  git ls-remote "${1:-$(git_dir)}" &> /dev/null
}

# Get number of commits
alias git_count_all='git_count --all'
git_count() {
  git rev-list ${1:-HEAD} --count
}

########################################
# Get hash
alias git_sha1='git_hash'
git_hash() {
  git rev-parse "${@:-HEAD}"
}
git_allhash() {
  git rev-list "${@:-HEAD}"
}

# Get short hash
alias git_ssha1='git_shorthash'
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
  local DIR="${4:-$(basename "$URL" .git)}"
  shift 3 2>/dev/null
  git clone "$URL" "$DIR" || break
  git --git-dir="$DIR/.git" remote rename origin "$REMOTE"
  git --git-dir="$DIR/.git" checkout "$BRANCH"
  for ARGS; do
    set -- $ARGS
    git remote add "$@"
  done
}

# Batch pull the current branch from all remotes
git_pull() {
	git_pull_all "${@:-}" "$(git_branch)"
}

# Batch pull existing remote/branches
if [ $(git_version) -gt $(git_version 2.9) ]; then
git_pull_all() {
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
      git stash save
      set -e
      CURRENT=\"$(git rev-parse --abbrev-ref HEAD)\"
      for BRANCH in $BRANCHES; do
        git checkout \"\$BRANCH\" >/dev/null || continue
        for REMOTE in $REMOTES; do
          if git branch -r | grep -- \"\$REMOTE/\$BRANCH\" >/dev/null; then
            if git ls-remote \"\$REMOTE\" | grep \"heads/\$BRANCH\" >/dev/null; then
              git fetch \"\$REMOTE\" \"\$BRANCH\"
              git pull --rebase --autostash \"\$REMOTE\" \"\$BRANCH\"
            else
              echo \"Cannot access repo '\$REMOTE/\$BRANCH'...\"
            fi
          fi
        done
      done
      git checkout -q \"$CURRENT\"
      set +e
      git stash pop
    "
  fi
}
else
git_pull_all() {
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
        git checkout \"\$BRANCH\" >/dev/null || continue
        for REMOTE in $REMOTES; do
          if git branch -r | grep -- \"\$REMOTE/\$BRANCH\" >/dev/null; then
            if git ls-remote \"\$REMOTE\" | grep \"heads/\$BRANCH\" >/dev/null; then
              git fetch \"\$REMOTE\" \"\$BRANCH\"
              if [ -x \"\$(git --exec-path)/git-pull\" ]; then
                git pull --rebase \"\$REMOTE\" \"\$BRANCH\"
              else
                git fetch \"\$REMOTE\" \"\$BRANCH\" &&
                git merge --ff-only \"\$REMOTE/\$BRANCH\"
              fi
            else
              echo \"Cannot access repo '\$REMOTE/\$BRANCH'...\"
            fi
          fi
        done
      done
      end
    "
  fi
}
fi

# Batch push the current branch to all remotes
git_push() {
	git_push_all "${@:-}" "$(git_branch)"
}

# Batch push existing remote/branches
git_push_all() {
  git_exists || return 1
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  for REMOTE in $REMOTES; do
    for BRANCH in $BRANCHES; do
      #if git branch -r | grep -- "$REMOTE/$BRANCH" >/dev/null; then
        echo -n "Push $REMOTE/$BRANCH : "
        git push "$REMOTE" "$BRANCH"
      #fi
    done
  done
}

# Create a bundle
git_bundle() {
  git_exists || return 1
  local DIR="${1:-$(git_dir)/bundle}"
  if [ -d "$DIR" ]; then
    local BUNDLE="$DIR/${2:-$(git_name "bundle").git}"
    local GPG_RECIPIENT="$3"
    local GPG_TRUST="${4:+--trust-model always}"
    echo "Git bundle into $BUNDLE"
    git bundle create "$BUNDLE" --all --tags --remotes
    if [ ! -z "$GPG_RECIPIENT" ]; then
      gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${BUNDLE}" &&
        (shred -fu "${BUNDLE}" || wipe -f -- "${BUNDLE}" || rm -- "${BUNDLE}")
    fi
    ls -l "${BUNDLE}"*
  else
    echo "Target directory '$DIR' does not exists."
    echo "Skip bundle creation..."
  fi
}

# Git upkeep
git_upkeep() {
  git_exists || return 1
  # Get args
  local ADD=""
  local DL=""
  local UL=""
  local MSG="[upkeep] auto-commit"
  local FLAG OPTIND OPTARG
  while getopts "vasdum" FLAG; do
    case "$FLAG" in
      v) vcsh_run git status;;
      a) ADD=1;;
      s) DL=1; UL=1;;
      d) DL=1;;
      u) UL=1;;
      m) MSG="$OPTARG";;
    esac
  done
  # Run
  if [ -n "$ADD" ]; then
    vcsh_run git add -v -u :/
    vcsh_run git commit -m "$MSG"
  fi
  if [ -n "$DL" ]; then
    git_pull
  fi
  if [ -n "$UL" ]; then
    vcsh_run git push
  fi
}

########################################
# Git diff all files
git_diff_all() {
  git diff "$@" 2>/dev/null
  git diff --cached "$@"
}
# Git diff all files with meld
git_diffm_all() {
  git difftool -y "$@" 2>/dev/null
  git difftool --cached -y "$@"
}

########################################

# Get stash name by index
git_stash_name() {
  git stash list | awk "NR==$((${1:-0}+1)){print \$2}"
}

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
git_stash_create() {
  local STASH="$(git_name)${1:+.$1}"; shift 2>/dev/null
  local REF="$(git stash create)"
  true "${REF:?Nothing to stash...}"
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
git_stash_apply_branch() {
  git stash branch "$(git_stash_name "${1:-0}")" "stash@{${1:-0}}"
}

# Show diff between stash and local copy
git_stash_diff() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git diff "stash@{$STASH}" "$@"
}
git_stash_diffm() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git difftool -y "stash@{$STASH}" "$@" 
}
git_stash_diffl() {
  git_stash_diff "${@:-0}" --name-only
}

# Show stash file list
git_stash_file() {
  local STASH="${1:-0}"; shift 2>/dev/null
  git stash show "stash@{$STASH}" "$@"
}
git_stash_file_all() {
  local START="${1:-0}"
  local NUM="${2:-$(git stash list | wc -l)}"
  shift 2 2>/dev/null
  while git stash list --skip $START -n 1; do
    git_stash_file $START
    START=$((START+1))
    eval "${1:-echo}"
  done
}

# Show stash file content
alias git_stash_patch='git_stash_cat'
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

########################################
# Clean repo back to given CL
# remove unversionned files
git_clean() {
  git_exists || return 1
  # Confirmation
  if [ "$1" != "-y" ]; then
    git clean -d -n --exclude=".*" "$@"
    ! ask_question "Proceed? (y/n) " y Y >/dev/null && return 0
  fi
  shift
  # Backup
  if [ "$2" != "-y" ] && ask_question "Backup? (y/n) " y Y >/dev/null; then
    local DST="$(git_dir)/clean"
    mkdir -p "$DST"
    git_stx '??' | xargs -0 7z a "$DST/clean.$(git_name).7z"
  fi
  # Clean repository
  git clean -d -f --exclude=".*" "$@"
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

# Amend author/committer names & emails
git_amend_names() {
(
  # Run in a subshell because we need to export lots of variables
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

########################################

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

# Reset file permissions
git_perms_reset() {
  git diff -p \
      | grep -E '^(diff|old mode|new mode)' \
      | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' \
      | git apply
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
# Find git directory
ff_git() {
	for DIR in "${@:-.}"; do
		find ${DIR:-.} -type d -name '*.git' -prune
	done
}
ff_git0() {
	for DIR in "${@:-.}"; do
		find ${DIR:-.} -type d -name '*.git' -prune -print0
	done
}
# Find git repo
git_find() {
	ff_git0 "${1:-.}" |
		while read -d $'\0' DIR; do
			git_exists "$DIR" && printf "'%s'\n" "$DIR"
		done 
}

# Git gc all
alias git_gc='git_find | xargs -I {} -n 1 sh -c "cd \"{}\"; git gc"'

########################################
# Create a tag
git_tag_create() {
  git tag "tag_$(date +%Y%m%d-%H%M%S)${1:+_$1}"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
