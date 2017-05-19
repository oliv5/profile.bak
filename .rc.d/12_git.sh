#!/bin/sh

# Editors
export GIT_EDITOR="${EDITOR:-vi}"
export GIT_PAGER="${PAGER:-less}"

########################################
# Dependencies

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
  # Forbid git annex in direct mode with VCSH
  if [ "$1" = "annex" -a -n "$(command git config --get vcsh.vcsh)" ]; then
    if [ "$(command git config --get annex.direct)" = "true" -o "$2" = "direct" ]; then
      echo "git annex in direct mode is not compatible with VCSH repositories..." >&2
      return 1
    fi
  fi
  # VCSH repository not loaded yet
  if [ -z "$GIT_WRAPPER" ] && [ -z "$VCSH_REPO_NAME" ] && command git config --get vcsh.vcsh >/dev/null 2>&1; then
    local GIT_WRAPPER=1
    vcsh "$(git_repo)" "$@"
  else
    command git "$@"
  fi
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
  local VERSION="${1:-$(git --version 2>/dev/null | cut -d' ' -f 3)}"
  expr $(echo $VERSION | awk -F'.' '{printf "%.d%.2d%.2d%.2d",$1,$2,$3,$4}')
}

# Check repo exists
git_exists() {
  #git ${1:+--work-tree="$1"} rev-parse --verify "HEAD" >/dev/null 2>&1
  #git ${1:+--git-dir="$1"} rev-parse --verify HEAD >/dev/null 2>&1
  git ${1:+--git-dir="$1"} rev-parse >/dev/null 2>&1
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
  readlink -f "${1:-${GIT_DIR:-$(git rev-parse --git-dir)}}"
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

# Get git root (git-dir for bare repos or worktree for non-bare repos)
git_root() {
  git_bare "$@" && git_dir "$@" || git_worktree "$@"
}

########################################

# Get current branch name
# Hide errors when ref is unknown
git_branch() {
  #git ${2:+--git-dir="$2"} rev-parse --abbrev-ref "${1:-HEAD}" 2>/dev/null
  #git branch -a | grep -E '^\*' | cut -c 3-
  #git for-each-ref --format='%(objectname) %(refname:short)' refs/heads | awk "/^$(git rev-parse HEAD)/ {print \$2}"
  # The following works for detached heads too
  git ${2:+--git-dir="$2"} describe --contains --all "${1:-HEAD}" 2>/dev/null
}

# Get current branch tracking
git_tracking() {
  git ${1:+--git-dir="$1"} rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
  #git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD) 2>/dev/null
}

# Get all local branches
git_branches() {
  #git ${1:+--git-dir="$1"} for-each-ref --shell refs/heads/ --format='%(refname:short)' | sed -e 's;heads/;;' | xargs echo 
  git ${1:+--git-dir="$1"} for-each-ref --format='%(refname:short)' refs/heads/ | xargs echo
}

# List all branches info
git_branches_info() {
  for branch in $(git branch -r $@ | grep -v HEAD); do
    echo -e $(git show --format="%ci %cr %an" $branch | head -n 1) \\t$branch
  done | sort -r
}

# Check a branch exists
git_branch_exists() {
  local BRANCH="${1}/"
  local REMOTE="${BRANCH#*/}"
  echo "$1" | grep -- '/' >/dev/null && BRANCH="remotes/$1" || BRANCH="heads/$1"
  #[ -n "$(git ${2:+--git-dir="$2"} for-each-ref --shell refs/${BRANCH})" ]
  git ${2:+--git-dir="$2"} show-ref "refs/${BRANCH}" >/dev/null
}

# Get merged branches
git_branch_merged() {
  git ${3:+--git-dir="$3"} branch --${2:+no-}merged ${1}
}

# Delete local untracked branch (safely)
git_branch_delete() {
  for BRANCH; do
    echo "Delete local branch '$BRANCH'"
    git tag "deleted.${BRANCH}_$(date +%Y%m%d-%H%M%S)" "refs/head/$BRANCH" &&
      git branch -d "$BRANCH"
  done
}

# Delete remote untracked branch
git_branch_delete_remote() {
  for BRANCH; do
    local REMOTE="${BRANCH%%/*}"
    local NAME="${BRANCH##*/}"
    echo "Delete remote branch '$BRANCH'"
    git tag "deleted.${REMOTE}.${NAME}.$(date +%Y%m%d-%H%M%S)" "remotes/$BRANCH" && { 
      git push "$REMOTE" ":$NAME" || git branch -rd "$BRANCH"
    }
  done
}

# Set an existing branch to a given SHA1
git_branch_jump() {
  git fetch . "${2:?No destination specified...}" "${1:?No source specified...}"
}

########################################
# Get remote url
git_url() {
  git ${2:+--git-dir="$2"} config --get remote.${1}.url
}

# Check if a repo has been modified
git_modified() {
  ! git ${1:+--git-dir="$1"} diff-index --quiet HEAD --
}

# Git status for scripts
git_st() {
  #git ${2:+--git-dir="$2"} status -s | awk '/^[\? ]?'$1'[\? ]?/ {print "\""$2"\""}'
  git ${2:+--git-dir="$2"} status -s | awk '/'"^[\? ]?$1"'/{print substr($0,4)}'
}
git_stx() {
  git ${2:+--git-dir="$2"} status -z | awk 'BEGIN{RS="\0"; ORS="\0"}/'"^[\? ]?$1"'/{print substr($0,4)}'
}

# Get remote names
git_remotes() {
  git ${1:+--git-dir="$1"} remote | xargs
}

# Get git backup name
git_name() {
  echo "$(git_repo).${1:+$1.}$(uname -n).$(git_branch | tr '/' '_').$(date +%Y%m%d-%H%M%S).$(git_shorthash)"
}

# Check a set of commands exist
git_cmd_exists() {
  local EXECPATH="$(git_exp)"
  for CMD; do
    [ -x "${EXECPATH}/git-${CMD}" ] || return 1
  done
  return 0
}

# Check a remote repo exists
git_ping() {
  git ${2:+--git-dir="$2"} ls-remote "${1:-$(git_dir)}" &> /dev/null
}

# Get number of commits
alias git_count_all='git_count --all'
git_count() {
  git ${2:+--git-dir="$2"} rev-list ${1:-HEAD} --count
}

# Check if we are in a detached head
git_detached() {
  [ -z "$(git ${1:+--git-dir="$1"} symbolic-ref --short -q HEAD)" ]
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
# Clone & rename remote
git_clone() {
  git clone "$1" ${3:+"$3"} || return 1
  if [ -n "$2" ]; then
    git --git-dir="${3:-$(basename "$1" .git)}/.git" remote rename origin "$2"
  fi
}

# Clone one branch only
git_clone_branch() {
  local URL="${1:?No URL specified}"
  local BRANCH="${2:-master}"
  local DIR="${3:-$(basename "$URL" .git)}"
  mkdir -p "$DIR"
  cd "$DIR" || return 1
  git init
  git remote add origin -t "$BRANCH" "$URL"
  git fetch
  git checkout "$BRANCH"
}

# Add batch of remotes
git_add_remotes() {
  git_exists || return 1
  while [ $# -ge 3 ]; do
    git remote add "$1" "$2" ${3:+-t "$3"}
    shift 3
  done
}

########################################

#~ # Batch pull the selected branches from their remote tracking
#~ alias git_pull='git_pull_branches "$(git_branch)"'
#~ alias git_pull_all='git_pull_branches'

#~ # Batch pull existing branches from their remote tracking
#~ if [ $(git_version) -gt $(git_version 2.9) ]; then
#~ git_pull_branches() {
  #~ git_exists || return 1
  #~ local IFS="$(printf ' \t\n')"
  #~ local BRANCHES="${1:-$(git_branches)}"
  #~ local FORCE="$([ "$2" = "-f" ] && echo "-f")"
  #~ if annex_direct; then
    #~ # Note: git annex repos in direct mode
    #~ # are not compatible with vcsh
    #~ git annex sync
  #~ else
    #~ CURRENT="$(git rev-parse --abbrev-ref HEAD)"
    #~ for BRANCH in $BRANCHES; do
      #~ # Is there a remote with this branch ?
      #~ if command git for-each-ref --shell refs/remotes | grep "refs/remotes/.*/$BRANCH'" >/dev/null; then
        #~ git checkout $FORCE "$BRANCH" >/dev/null || continue
        #~ git pull --rebase --autostash || exit $?
        #~ echo "-----"
      #~ fi
    #~ done
    #~ git checkout -fq "$CURRENT"
  #~ fi
#~ }
#~ else
#~ git_pull_branches() {
  #~ git_exists || return 1
  #~ local IFS="$(printf ' \t\n')"
  #~ local BRANCHES="${1:-$(git_branches)}"
  #~ local FORCE="$([ "$2" = "-f" ] && echo "-f")"
  #~ if annex_direct; then
    #~ # Note: git annex repos in direct mode
    #~ # are not compatible with vcsh
    #~ git annex sync
  #~ else
    #~ end() {
      #~ trap - INT TERM
      #~ unset -f end
      #~ git checkout -fq "$CURRENT"
      #~ if [ -n "$STASH" ]; then
        #~ git stash apply -q --index "$STASH"
      #~ fi
    #~ }
    #~ set +e
    #~ STASH="$(git stash create 2>/dev/null)"
    #~ trap end INT TERM
    #~ if [ -n "$STASH" ]; then
      #~ git reset --hard HEAD -q --
    #~ fi
    #~ CURRENT="$(git rev-parse --abbrev-ref HEAD)"
    #~ for BRANCH in $BRANCHES; do
      #~ # Is there a remote with this branch ?
      #~ if command git for-each-ref --shell refs/remotes | grep "refs/remotes/.*/$BRANCH'" >/dev/null; then
        #~ git checkout $FORCE "$BRANCH" >/dev/null || continue
        #~ if [ -x "$(git --exec-path)/git-pull" ]; then
          #~ git pull --rebase || exit $?
        #~ else
          #~ git merge --ff-only "$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)" || exit $?
        #~ fi
        #~ echo "-----"
      #~ fi
    #~ done
    #~ end
  #~ fi
#~ }
#~ fi

# Batch pull the selected branches from their remote tracking
alias git_pull='git_pull_remotes ""'
alias git_pull_all='git_pull_remotes'

# Batch pull existing remote branches
if [ $(git_version) -gt $(git_version 2.9) ]; then
git_pull_remotes() {
  git_exists || return 1
  local IFS="$(printf ' \t\n')"
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  local FORCE="$([ "$3" = "-f" ] && echo "-f")"
  if annex_direct; then
    # Note: git annex repos in direct mode
    # are not compatible with vcsh
    git annex sync
  else
    CURRENT="$(git rev-parse --abbrev-ref HEAD)"
    git fetch --all 2>/dev/null
    for BRANCH in $BRANCHES; do
      # Is there a remote with this branch ?
      if command git for-each-ref --shell refs/remotes | grep "refs/remotes/.*/$BRANCH'" >/dev/null; then
        git checkout $FORCE "$BRANCH" >/dev/null || continue
        for REMOTE in $REMOTES; do
          # Does this remote have this branch ?
          if command git show-ref "refs/remotes/$REMOTE/$BRANCH" >/dev/null; then
            git pull --rebase --autostash "$REMOTE" "$BRANCH" || exit $?
            echo "-----"
          fi
        done
      fi
    done
    git checkout -fq "$CURRENT"
  fi
}
else
git_pull_remotes() {
  git_exists || return 1
  local IFS="$(printf ' \t\n')"
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  local FORCE="$([ "$3" = "-f" ] && echo "-f")"
  if annex_direct; then
    # Note: git annex repos in direct mode
    # are not compatible with vcsh
    git annex sync
  else
    end() {
      trap - INT TERM
      unset -f end
      git checkout -fq "$CURRENT"
      if [ -n "$STASH" ]; then
        git stash apply -q --index "$STASH"
      fi
    }
    set +e
    STASH="$(git stash create 2>/dev/null)"
    trap end INT TERM
    if [ -n "$STASH" ]; then
      git reset --hard HEAD -q --
    fi
    CURRENT="$(git rev-parse --abbrev-ref HEAD)"
    git fetch --all 2>/dev/null
    for BRANCH in $BRANCHES; do
      # Is there a remote with this branch ?
      if command git for-each-ref --shell refs/remotes | grep "refs/remotes/.*/$BRANCH'" >/dev/null; then
        git checkout $FORCE "$BRANCH" >/dev/null || continue
        for REMOTE in $REMOTES; do
          # Does this remote have this branch ?
          if command git show-ref "refs/remotes/$REMOTE/$BRANCH" >/dev/null; then
            if [ -x "$(git --exec-path)/git-pull" ]; then
              git pull --rebase "$REMOTE" "$BRANCH" || exit $?
            else
              git merge --ff-only "$REMOTE/$BRANCH" || exit $?
            fi
            echo "-----"
          fi
        done
      fi
    done
    end
  fi
}
fi

# Batch push to all existing remote/branches
alias git_push='git_push_all "" "$(git_branch)"'
git_push_all() {
  git_exists || return 1
  local IFS="$(printf ' \t\n')"
  local REMOTES="${1:-$(git_remotes)}"
  local BRANCHES="${2:-$(git_branches)}"
  for REMOTE in $REMOTES; do
    for BRANCH in $BRANCHES; do
      if git_branch_exists "$REMOTE/$BRANCH"; then
        echo -n "Push $REMOTE/$BRANCH : "
        git push "$REMOTE" "$BRANCH"
      fi
    done
  done
}

# Set default upstream on the specified branches
git_set_tracking() {
  git_exists || return 1
  local IFS="$(printf ' \t\n')"
  local REMOTE="${1:?No remote specified. Possible remotes are: $(git_remotes)}"
  local BRANCHES="${2:-$(git_branch)}"
  git fetch --all 2>/dev/null
  for BRANCH in $BRANCHES; do
    if git for-each-ref "refs/remotes/$REMOTE" | grep -- "refs/remotes/$REMOTE/$BRANCH\$" >/dev/null; then
      git branch -u "$REMOTE/$BRANCH" "$BRANCH"
    fi
  done
}

# Get default upstream on the specified branches
alias git_get_tracking='git_get_all_tracking "$(git_branch)"'
alias git_get_tracking_remote='git_get_all_tracking "$(git_branch)" | sed -s "s;/.*;;"'
alias git_get_tracking_branch='git_get_all_tracking "$(git_branch)" | sed -s "s;.*/;;"'
git_get_all_tracking() {
  git_exists || return 1
  local IFS="$(printf ' \t\n')"
  local BRANCHES="${1:-$(git_branches)}"
  for BRANCH in $BRANCHES; do
    git rev-parse --abbrev-ref "$BRANCH@{upstream}"
  done
}

# Create a bundle
git_bundle() {
  ( set +e; # Need to go on
  git_exists || return 1
  local DIR="${1:-$(git_dir)/bundle}"
  mkdir -p "$DIR"
  if [ -d "$DIR" ]; then
    local BUNDLE="$DIR/${2:-$(git_name "bundle").git}"
    local GPG_RECIPIENT="$3"
    local GPG_TRUST="${4:+--trust-model always}"
    echo "Git bundle into $BUNDLE"
    git bundle create "$BUNDLE" --all
    if [ ! -z "$GPG_RECIPIENT" ]; then
      gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${BUNDLE}" &&
        (shred -fu "${BUNDLE}" || wipe -f -- "${BUNDLE}" || rm -- "${BUNDLE}")
    fi
    ls -l "${BUNDLE}"*
  else
    echo "Target directory '$DIR' does not exists."
    echo "Skip bundle creation..."
    exit 1
  fi
  )
}

# Git upkeep
git_upkeep() {
  local DBG=""
  local NEW=""
  local DEL=""
  local COMMIT=""
  local MSG="git_upkeep() at $(date +%Y%m%d-%H%M%S)"
  local PULL=""
  local PUSH=""
  local REMOTES=""
  # Get arguments
  #echo "[git_upkeep] arguments: $@"
  while getopts "andcpur:m:zh" OPTFLAG; do
    case "$OPTFLAG" in
      a) NEW=1; DEL=1;;
      n) NEW=1;;
      d) DEL=1;;
      c) COMMIT=1;;
      m) MSG="$OPTARG";;
      p) PULL=1;;
      u) PUSH=1;;
      r) REMOTES="$OPTARG";;
      z) set -vx; DBG="true";;
      *) echo >&2 "Usage: git_upkeep [-a] [-n] [-d] [-c] [-p] [-u] [-r 'remotes'] [-m 'msg'] [-z]"
         echo >&2 "-a stage (a)ll files"
         echo >&2 "-n stage (n)ew files"
         echo >&2 "-d stage (d)eleted files"
         echo >&2 "-c (c)ommit files"
         echo >&2 "-p (p)ull"
         echo >&2 "-u p(u)sh"
         echo >&2 "-r (r)remotes to pull/push"
         echo >&2 "-m commit (m)essage"
         echo >&2 "-z (s)imulate operations"
         return 1
         ;;
    esac
  done
  shift "$((OPTIND-1))"
  unset OPTFLAG OPTARG
  OPTIND=1
  [ $# -ne 0 ] && echo "Bad parameters: $@" && return 1
  # Main
  git_exists || return 1
  #echo "[git_upkeep] start at $(date)"
  # Add
  if [ -n "$DEL" ]; then
      git_stx "^D[ M]|^ D" | xargs -r0 $DBG git add --all --ignore-error --
  fi
  if [ -n "$NEW" ]; then
      $DBG git add -u || return $?
  fi
  # Commit
  if [ -n "$COMMIT" ]; then
      $DBG git commit -m "$MSG" || return 0 # return 0 when nothing to be committed
  fi
  # Pull
  if [ -n "$PULL" ]; then
    for REMOTE in ${REMOTES:-""}; do
      $DBG git pull --rebase $REMOTE || return $?
    done
  fi
  # Push
  if [ -n "$PUSH" ]; then
    for REMOTE in ${REMOTES:-""}; do
      $DBG git push $REMOTE || return $?
    done
  fi
  #echo "[git_upkeep] end at $(date)"
}

########################################
# Normal to bare repo
git_tobare() {
  local SRC="${1:-$PWD}"
  local DST="${SRC}.git"
  git_exists "$SRC/.git" &&
  mv "$SRC/.git" "$DST" &&
  git --git-dir="$DST" config --bool core.bare true &&
  rm -r "$SRC"
}

# Bare to normal repo
git_frombare() {
  local SRC="${1:-$PWD}"
  local DST="${SRC%%.git}"
  git_exists "$SRC" &&
  mkdir "${SRC%%.git}" &&
  mv "$SRC" "$DST/.git" &&
  git --git-dir="$DST/.git" config --bool core.bare false &&
  git --git-dir="$DST/.git" --work-tree="$DST" reset --hard HEAD --
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
  local IFS="$(printf '\n')"
  local DESCR
  mkdir -p "$DST"
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
  #git ${3:+--git-dir="$3"} ls-tree -r ${1:-$(git_branch "" "$3")} --name-only ${2:+| grep -F "$2"}
  git ls-files "$@"
}

# List files in commit
git_ls_commit() {
  #git show --pretty="format:" --name-only "${@:-HEAD}"
  #git ${2:+--git-dir="$2"} diff-tree --no-commit-id --name-only -r "${1:-HEAD}"
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

# Git cleanup
# https://gist.github.com/Zoramite/2039636
git_cleanup() {
  # Verifies the connectivity and validity of the objects in the database
  git fsck —unreachable
  # Manage reflog information
  git reflog expire —expire=0 —all
  # Pack unpacked objects in a repository
  git repack -a -d -l
  # Prune all unreachable objects from the object database
  git prune
  # Cleanup unnecessary files and optimize the local repository
  git gc —aggressive
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
# Git gc all
alias git_gc='git_find | xargs -I {} -n 1 sh -c "cd \"{}\"; pwd; git gc"'
alias git_repack='git_find | xargs -I {} -n 1 sh -c "cd \"{}\"; pwd; git repack -d"'
alias git_pack='git_find | xargs -I {} -n 1 sh -c "cd \"{}\"; pwd; git repack -d; git prune; git gc"'

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
  ## Bash only (read -d)
  #ff_git0 "${1:-.}" |
  #  while IFS= read -r -d $'\0' DIR; do
  #   git_exists "$DIR" && printf "'%s'\n" "$DIR"
  # done
  for DIR in "${@:-.}"; do
    find ${DIR:-.} -type d -name '*.git' -prune -exec sh -c '
      for DIR; do
        git --git-dir="$DIR" rev-parse >/dev/null 2>&1 && printf "'%s'\\n" "$DIR"
      done
    ' _ {} +
  done
}
git_find0() {
  ## Bash only (read -d)
  #ff_git0 "${1:-.}" |
  # while IFS= read -r -d $'\0' DIR; do
  #   git_exists "$DIR" && printf "%s\0" "$DIR"
  # done
  for DIR in "${@:-.}"; do
    find ${DIR:-.} -type d -name '*.git' -prune -exec sh -c '
      for DIR; do
        git --git-dir="$DIR" rev-parse >/dev/null 2>&1 && printf "%s\0" "$DIR"
      done
    ' _ {} +
  done
}

########################################
# Create a tag
git_tag_create() {
  git tag "tag_$(date +%Y%m%d-%H%M%S).$(git_branch)${1:+_$1}"
}

########################################
# Easy amend of previous commit
git_squash() {
  local COMMIT="${1:-HEAD}"
  local AHEAD="${2:-2}"
  git commit --squash="$COMMIT" -m ""
  git rebase --interactive --autosquash "${COMMIT}~${AHEAD}"
}
git_fixup() {
  local COMMIT="${1:-HEAD}"
  local AHEAD="${2:-2}"
  git commit --fixup="$COMMIT" -m ""
  git rebase --interactive --autosquash "${COMMIT}~${AHEAD}"
}

########################################
# Git clone gcrypt repo
git_clone_gcrypt() {
  local URL="${1:?No URL specified...}"
  local KEY="${2:?No key specified...}"
  local DIR="${3:-$(basename "$URL" .git)}"
  local REMOTE="${4:-origin}"
  local BRANCH="${4:-master}"
  ! git_exists "$DIR/.git" || return 1
  mkdir -p "$DIR"
  git --git-dir="$DIR/.git" init
  git --git-dir="$DIR/.git" remote add "$REMOTE" "gcrypt::${URL}"
  git --git-dir="$DIR/.git" config "remote.${REMOTE}.gcrypt-participants" "$KEY"
  (cd "$DIR"; git pull "$REMOTE" "$BRANCH")
}

# Git add gcrypt remote
git_add_gcrypt_remote() {
  local NAME="${1:?No remote name specified...}"
  local URL="${2:?No URL specified...}"
  local KEY="${3:?No key specified...}"
  local DIR="${4:-.}"
  git_exists "$DIR/.git" || return 1
  git --git-dir="$DIR/.git" remote add "$NAME" "gcrypt::${URL}"
  git --git-dir="$DIR/.git" config remote.${NAME}.gcrypt-participants "$KEY"
}

########################################
# https://gist.github.com/smileyborg/913fe3221edfad996f06
# Check if commit is an evil merge
git_evil_merge() {
  local SHA1="${1:?No commit specified...}"
  local GIT="${2:-$PWD}"
  local TMP="$(mktemp)"
  # Get current HEAD rev
  local HEAD="$(git -C "$GIT" symbolic-ref --short -q HEAD)" ||
  HEAD="$(git -C "$GIT" rev-parse HEAD)" # detached HEAD, get the SHA1
  # Stash changes
  local STASH="$(git -C "$GIT" stash 2>/dev/null)"
  # Perform the merge without resolving conflicts. Then diff the result with the actual merge commit we're inspecting.
  git -C "$GIT" checkout "${SHA1}~" &>/dev/null
  git -C "$GIT" -c merge.conflictstyle=diff3 merge --no-ff "${SHA1}^2" --no-commit &>/dev/null
  git -C "$GIT" add $(git -C "$GIT" status -s | cut -c 3-) &>/dev/null
  git -C "$GIT" commit --no-edit &>/dev/null
  git -C "$GIT" diff "HEAD..$SHA1" > "$TMP"
  # Restore repository
  git -C "$GIT" checkout "$HEAD" &>/dev/null
  # Restore stash
  [ -n "$STASH" ] && git -C "$GIT" stash pop
}

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
alias gbvv='git branch -v'  # double-verbose list local
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
alias glS='git log -S'
alias gll='git log --pretty=oneline --abbrev-commit'
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
# Patch aliases
alias gpm='git diff -p'
alias gpf='git format-patch -1'
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
alias grh1='git reset HEAD~'
alias grh2='git reset HEAD~2'
alias grhh='git reset HEAD --hard'
alias git_rollback='git reset'
# Amend last commit
alias git_amend='git commit --amend'
alias gam='git commit --amend'
# Cherry-pick
alias gcp='git cherry-pick'
# Rebase aliases
alias grb='git rebase'
alias grbi='git rebase -i'
# Fetch/pull/push aliases
alias gpu='git push'
alias gpua='git_push_all'
if [ $(git_version) -gt $(git_version 2.9) ]; then
  alias gup='git pull --rebase --autostash'
else
  alias gup='git pull --rebase'
fi
alias gupa='git_pull_all'
alias gfe='git fetch'
alias gfa='git fetch --all'
# Config aliases
alias gcg='git config --get'
alias gcs='git config --set'
alias gcl='git config -l'
alias gcf='git config -l'
alias gcfg='git config -g'
alias gconfig='git config'
# Git ignore changes
alias git_ignore_changes='git update-index --assume-unchanged'
alias git_noignore_changes='git update-index --no-assume-unchanged'
# cd aliases
alias gr='cd "$(git_root)"'
# gitk aliases
alias gk='gitk'

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#git}" != "$1" ] && "$@" || true

