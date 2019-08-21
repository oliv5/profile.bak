#!/bin/sh

# Editors
export GIT_EDITOR="${EDITOR:-vi}"
export GIT_PAGER="${PAGER:-less}"

########################################
# Dependencies

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
#git() {
#  # Forbid git annex in direct mode with VCSH
#  if [ "$1" = "annex" -a -n "$(command git config --get vcsh.vcsh)" ]; then
#    if [ "$(command git config --get annex.direct)" = "true" -o "$2" = "direct" ]; then
#      echo "git annex in direct mode is not compatible with VCSH repositories..." >&2
#      return 1
#    fi
#  fi
#  # VCSH repository not loaded yet
#  if [ -z "$GIT_WRAPPER" ] && [ -z "$VCSH_REPO_NAME" ] && command git config --get vcsh.vcsh >/dev/null 2>&1; then
#    local GIT_WRAPPER=1
#    vcsh "$(git_repo)" "$@"
#  else
#    command git "$@"
#  fi
#}

########################################
# Env setup
git_setup() {
  # Push (either simple, upstream or current)
  git config --global --unset-all push.default
  git config --global --add push.default current
  # Diff
  git config --global --unset-all diff.tool; git config --unset-all diff.tool
  git config --global diff.tool meld
  git config --global alias.meld '!$HOME/pbin/git-meld.pl'
  # Merge
  git config --global --unset-all merge.tool; git config --unset-all merge.tool
  git config --global merge.tool mymerge
  git config --global merge.conflictstyle diff3
  git config --global mergetool.mymerge.cmd \
    'meld --diff "$BASE" "$LOCAL" --diff "$BASE" "$REMOTE" --diff "$LOCAL" "$MERGED" "$REMOTE"'
  git config --global mergetool.mymerge.trustExitCode true
  # Misc
  git config --global rerere.enabled true
  git config --global core.excludesfile '~/.gitignore'
}

########################################
# Get git version
git_version() {
  local VERSION="${1:-$(git --version 2>/dev/null | cut -d' ' -f 3)}"
  echo "$VERSION" | awk -F'.' '{r=sprintf("%.d%.2d%.2d%.2d",$1,$2,$3,$4); sub("^0+","0",r); print r}'
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
git_user_dir() {
  echo "$(git_dir "$@")/user"
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

# Check if we are at the top level directory
git_top() {
  [ "$(git_root 2>/dev/null)" = "$PWD" ]
}

# Unlock repo
git_unlock() {
  rm -v "$(git_dir "$@")/index.lock"
}

########################################

# Get current branch name
# Hide errors when ref is unknown
git_branch() {
  #git ${2:+--git-dir="$2"} rev-parse --abbrev-ref "${1:-HEAD}" 2>/dev/null
  #git branch -a | grep -E '^\*' | cut -c 3-
  #git for-each-ref --format='%(objectname) %(refname:short)' refs/heads | awk "/^$(git rev-parse HEAD)/ {print \$2}"
  # The following works for detached heads too
  #{ git ${2:+--git-dir="$2"} symbolic-ref "${1:-HEAD}" 2>/dev/null || echo "detached_head"; } | sed 's;refs/heads/;;'
  git ${2:+--git-dir="$2"} symbolic-ref --short "${1:-HEAD}" 2>/dev/null || echo "detached_head"
}

# Get current branch tracking
alias git_tracking_remote='git_tracking | sed -s "s;/.*;;"'
alias git_tracking_branch='git_tracking | sed -s "s;.*/;;"'
git_tracking() {
  git ${2:+--git-dir="$2"} rev-parse --abbrev-ref --symbolic-full-name "$1@{upstream}" 2>/dev/null | grep -v '@{upstream}'
  #git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD) 2>/dev/null
}

# Set default tracking
if [ $(git_version) -ge $(git_version 2.0) ]; then
git_set_tracking() {
  local BRANCH="${1:-$(git_branch)}"
  local REMOTE="${2:-$(git_remotes | cut -d' ' -f 1)}"
  if git for-each-ref "refs/remotes/$REMOTE" | grep -- "refs/remotes/$REMOTE/$BRANCH\$" >/dev/null; then
    git ${3:+--git-dir="$3"} branch --set-upstream-to "$REMOTE/$BRANCH" "$BRANCH"
  fi
}
else
git_set_tracking() {
  local BRANCH="${1:-$(git_branch)}"
  local REMOTE="${2:-$(git_remotes | cut -d' ' -f 1)}"
  if git for-each-ref "refs/remotes/$REMOTE" | grep -- "refs/remotes/$REMOTE/$BRANCH\$" >/dev/null; then
    git branch --set-upstream "$REMOTE/$BRANCH" "$BRANCH"
  fi
}
fi

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

# Set an existing branch to a given SHA1 without checking it out
git_branch_jump() {
  git fetch . "${2:?No destination specified...}" "${1:?No source specified...}"
}

# Delete local untracked branch (safely)
git_branch_delete() {
  for REFS; do
    local BRANCH="${REFS#*/}"
    echo "Delete local branch '$BRANCH'"
    git tag "$(git_name deleted.local)" "refs/head/$BRANCH" &&
      git branch -d "$BRANCH"
  done
}

# List remote branches
git_branches_remote() {
  git ls-remote --heads | awk '{print substr($2,12)}'
}

# Delete remote untracked branch
git_branch_delete_remote() {
  for REFS; do
    local REMOTE="${REFS%%/*}"
    local BRANCH="${REFS#*/}"
    echo "Delete remote branch '$REFS'"
    git tag "$(git_name deleted.remote.${REMOTE#*/})" "remotes/$REFS" && {
      git push "$REMOTE" ":$BRANCH" || git branch -rd "$REFS"
    }
  done
}

# Delete local and remote branches
git_branch_delete_both() {
  for REFS; do
    git_branch_delete "$REFS"
    git_branch_delete_remote "$REFS"
  done
}

# Rename remote branch
git_branch_rename_remote() {
  local OLD="${1:?No old branch name specified...}"
  local NEW="${2:?No new branch name specified...}"
  local REMOTE="${3:-origin}"
  git checkout "$OLD" &&
  git pull --ff-only &&
  git branch -m "$OLD" "$NEW" &&
  git push "$REMOTE" --delete "refs/heads/$OLD" &&
  git push "$REMOTE" "$NEW"
}

########################################
# Get remote url
git_url() {
  git ${2:+--git-dir="$2"} config --get remote.${1}.url
}

# Check if a repo has been modified
# https://stackoverflow.com/questions/5139290/how-to-check-if-theres-nothing-to-be-committed-in-the-current-branch
git_modified() {
  #! git ${1:+--git-dir="$1"} diff-files --quiet --ignore-submodules || ! git ${1:+--git-dir="$1"} diff-index --cached --quiet --ignore-submodules HEAD --
  ! git ${1:+--git-dir="$1"} diff --quiet || ! git ${1:+--git-dir="$1"} diff --cached --quiet
}

# Check if repo has untracked files
git_untracked() {
  [ "$(git ${1:+--git-dir="$1"} ls-files --other --exclude-standard --directory)" != "" ]
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

# Check remote registration
git_remote_exists() {
  git ${2:+--git-dir="$2"} remote | grep -E "$1" >/dev/null
}

# Get git backup name
git_name() {
  echo "$(git_repo).${1:+$1.}$(uname -n).$(git_branch | tr '/' '_').$(date +%Y%m%d-%H%M%S).$(git_shorthash)${2:+.$2}"
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
  git ${2:+--git-dir="$2"} rev-parse "${1:-HEAD}"
}
git_allhash() {
  git ${2:+--git-dir="$2"} rev-list "${1:-HEAD}"
}
alias git_firsthash='git_roothash'
git_roothash() {
  git ${2:+--git-dir="$2"} rev-list --max-parents=0 "${1:-HEAD}" 2>/dev/null ||
  git ${2:+--git-dir="$2"} rev-list --parents "${1:-HEAD}" | egrep --color=never "^[a-f0-9]{40}$"
}

# Get short hash
alias git_ssha1='git_shorthash'
git_shorthash() {
  git_hash "$@" | cut -c 1-8
}
git_allshorthash() {
  git_allhash "$@" | cut -c 1-8
}
git_rootshorthash() {
  git_roothash "$@" | cut -c 1-8
}

########################################
# Get git author
git_author() {
  local REF
  for REF; do
    git log --format='%ae' "${REF}^!"
  done
}

########################################
# Extract a path from a repo without cloning/checking it out
git_extract() {
  local URL="${1:?No url specified...}"
  local REF="${2:?No refs specified...}"
  local DIR="${3:?No DIR specified...}"
  git archive --format=tar --remote="$URL" "$REF" -- "$DIR" | tar xv
}

########################################
# Full-import (including all branches/tags)
git_import_bare() {
  git clone --mirror "${1:?No source specified...}"
}
git_import() {
  git_import_bare "$1" &&
  git_frombare "$1"
}

########################################

# Push the current branch to all remotes
git_push() { git_push_all "$2" "${1:-$(git_branch)}"; }

# Batch push to all existing remote/branches
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

########################################

# Secure file deletion
_git_secure_delete() {
  echo "Remove file '$1'"
  { command -v shred >/dev/null && shred -fu "$1"; } ||
  { command -v wipe >/dev/null && wipe -f -- "$1"; } ||
  rm -- "$1"
}

# Create a bundle
git_bundle() {
  ( set +e; # Need to go on
    git_exists || return 1
    local OUT="${1:-$(git_user_dir)/bundle/$(git_name).bundle}"
    [ -z "${OUT##*/}" ] && OUT="${OUT%/*}/$(git_name).bundle"
    OUT="${OUT%%.xz}"; OUT="${OUT%%.git}.git.xz"
    mkdir -p "$(dirname "$OUT")"
    if [ $? -eq 0 ]; then
      local GPG_RECIPIENT="$2"
      local GPG_TRUST="${3:+--trust-model always}"
      local OWNER="${4:-$USER}"
      echo "Git bundle into $OUT"
      git bundle create "${OUT%%.xz}" --all
      xz -k -z -9 -S .xz --verbose "${OUT%%.xz}" &&
        _git_secure_delete "${OUT%%.xz}"
      chown "$OWNER" "$OUT"
      if [ ! -z "$GPG_RECIPIENT" ]; then
        echo "Encrypting bundle into '${OUT}.gpg'"
        gpg -v --output "${OUT}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${OUT}" &&
          _git_secure_delete "${OUT}"
        chown "$OWNER" "${OUT}.gpg"
      fi
      ls -l "${OUT}"*
    else
      echo "Cannot create directory '$(dirname "$OUT")'. Abort..."
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
         echo >&2 "-z simulate operations"
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
  # Force PULL if a remote is using gcrypt
  if [ -z "$PULL" ] && [ -n "$PUSH" ] && git_gcrypt $REMOTES; then
    echo "Force pull because of gcrypt remote(s)"
    PULL=1
  fi
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
}

########################################
# Normal to bare repo
git_tobare() {
  local DIR="${1:-$PWD}"
  local TMP="${DIR}.git"
  git_exists "$DIR/.git" &&
  mv "$DIR/.git" "$TMP" &&
  rm -r "$DIR" &&
  mv "$TMP" "$DIR" &&
  command cd . &&
  git --git-dir="$DIR" config --bool core.bare true
}

# Bare to normal repo
git_frombare() {
  local DIR="${1:-$PWD}"
  git_exists "$DIR" &&
  mkdir -p "$DIR/.git" &&
  mv "$DIR"/* "$DIR/.git" &&
  git --git-dir="$DIR/.git" config --bool core.bare false &&
  git --git-dir="$DIR/.git" --work-tree="$DIR" reset --hard HEAD --
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

# Get stash count
git_stash_count() {
  git stash list | wc -l
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
  if [ $(git_stash_count) -eq 0 ]; then
    git stash save -q "$STASH" &&
    git stash apply -q
  else
    local REF="$(git stash create)"
    true "${REF:?Nothing to stash...}"
    git stash store -m "$STASH" "$REF" 2>/dev/null ||
      git update-ref -m "$STASH" refs/stash "$REF"
  fi
}

# Pop change from stash
git_stash_pop() {
  git stash pop "stash@{${1:-0}}"
}
git_stash_pop_forced() {
  git stash show -p "stash@{${1:-0}}" | git apply && git stash drop "stash@{${1:-0}}"
}

# Apply change from stash
git_stash_apply() {
  git stash apply "stash@{${1:-0}}"
}
git_stash_apply_forced() {
  git stash show -p "stash@{${1:-0}}" | git apply
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
  local DST="$(git_user_dir)/stash"
  local IFS="$(printf '\n')"
  mkdir -p "$DST"
  git stash list --format="%H %h %s" | while IFS=" " read -r HASH SHORT NAME; do
    NAME="$(echo "$NAME" | awk -F: '{gsub(/^ */,"",$2); gsub(/ /,"_",$2);print $2}' | cut -c -80)"
    local FILE="$DST/stash_${SHORT}_head_${NAME}.gz"
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
    local DST="$(git_user_dir)/clean"
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

# List deleted files
git_deleted() {
  git diff-tree -r "${@:-HEAD}" --diff-filter=AD --raw | awk '
    function basename(file) {
      sub(".*/", "", file)
      return file
    }
    {
      # Remove empty hash
      gsub("0{40}","")
      # Get parameters, nullify $1-$4
      hash=$3
      action=$4
      $1=$2=$3=$4=""
      file=$0
      sub("    ", "", file)
      name=basename(file)
      # Filter added-deleted files
      if ((hash in seen) || (name in seen)) {
        delete deleted[hash]
      } else if (action == "D") {
        deleted[hash]=file
      }
      seen[hash]=file
      seen[name]=file
    }
    END {
      for (x in deleted) {
        print deleted[x]
      }
    }
  '
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

# Amend commit log (with git filter-branch).
git_amend_log() {
  ( set -e
    local FROM="$(git_hash ${1:?No SHA1_1 specified...})"
    local NEWLOG="${2:?No new log specified...}"
    local TO="${3:-$(git_branch)}"
    local BRANCH="${4:-$(git_branch)}"
    git_modified && return 1
    #git_tag_create "git_amend_log"
    git branch _tmp_git_amend_log "${TO}"
    local SCRIPT="if [ \"\$GIT_COMMIT\" = \"$FROM\" ]; then echo \"$NEWLOG\"; else cat; fi"
    git filter-branch -f --msg-filter "$SCRIPT" -- ${FROM}^.._tmp_git_amend_log || true
    echo "Previous head was: $(git_hash)"
    git update-ref refs/heads/"$BRANCH" refs/heads/_tmp_git_amend_log
    git branch -d _tmp_git_amend_log
  )
}

# Amend commit file (with git filter-branch).
git_amend_file() {
  ( set -e
    local FROM="$(git_hash ${1:?No SHA1_1 specified...})"
    local TO="${2:-$(git_branch)}"
    local BRANCH="${3:-$(git_branch)}"
    ! git_modified && return 1
    git stash
    git branch _tmp_git_amend_log "${TO}"
    local SCRIPT="git stash show -p | git apply"
    git filter-branch -f --tree-filter "$SCRIPT" -- ${FROM}.._tmp_git_amend_log || true
    echo "Previous head was: $(git_hash)"
    git update-ref refs/heads/"$BRANCH" refs/heads/_tmp_git_amend_log
    git branch -d _tmp_git_amend_log
    git stash pop
  )
}

# Prune a given file from history
git_prune_file() {
  local FILE="${1:?No path specified...}"
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch '$FILE'" \
    --prune-empty --tag-name-filter cat -- --all
}

# Purge commits from a given author
git_prune_author() {
  local NAME="${1:?No name specified...}"
  local REV="${2:-HEAD}"
  git filter-branch --commit-filter \
    'if [ "$GIT_AUTHOR_NAME" = "$NAME" ]; then skip_commit "$@"; else git commit-tree "$@"; fi' \
    "$REV"
}

########################################
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
  local DST="${1:-$(git_user_dir)/backup/backup.$(git_name)}"
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
    git add "$(git_user_dir)/cache_meta" -f
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

# Search for a string in HEAD a commit
git_grep() {
  git grep "$@" ||
    git log -S "$@" --source --all
}

# Show history
alias git_history='git log -p'

# Search in history
git_search() {
  git grep "$@" $(git rev-list --all) ||
    git log -S "$@" --source --all
}

########################################
# Git gc all
alias git_gc='git_find0 | xargs -r0 -I {} -n 1 sh -c "cd \"{}\"; pwd; git gc"'
alias git_repack='git_find0 | xargs -r0 -I {} -n 1 sh -c "cd \"{}\"; pwd; git repack -d"'
alias git_pack='git_find0 | xargs -r0 -I {} -n 1 sh -c "cd \"{}\"; pwd; git repack -d; git prune; git gc"'

# Find git repo
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
git_find() {
  git_find0 "$@" | xargs
}

########################################
# Create a tag
git_tag_create() {
  git tag "tag_$(date +%Y%m%d-%H%M%S).$(git_branch)${1:+_$1}"
}

# Delete a tag totally (local & remotes)
git_tag_delete() {
  local REMOTES="$(git_remotes)"
  git tag -l "$@" | xargs -rn 1 -I{} sh -c '
    TAG="$1"; shift
    for REMOTE; do
      git push "$REMOTE" :refs/tags/${TAG} || exit 1
    done
    git tag -d "$TAG"
  ' _ {} $REMOTES
}

# Get previous tag
git_tag_prev() {
  for FROM in "${@:-}"; do
    git describe --tags --abbrev=0 ${FROM:+${FROM}^}
  done
}

# List previous tags in a range of commits
git_tag_list_prev() {
  local FROM="${1:-HEAD}"
  local TO="$(git tag -l $2)"
  while [ "$FROM" != "$TO" ]; do
    FROM="$(git describe --tags --abbrev=0 ${FROM:+${FROM}^} 2>/dev/null)"
    [ -n "$FROM" ] && echo "$FROM"
  done
}

# Test tag existenz
git_tag_exists() {
  loca REF="${1:?No ref specified...}"
  git show-ref --tags -d | grep -qe "$(git rev-parse "$REF")" >/dev/null 2>&1
}

########################################
# Easy amend of previous commit
git_squash() {
  local COMMIT="${1:-HEAD}"
  git_modified && git commit --squash="$COMMIT"
  git rebase --interactive --autosquash "${COMMIT}~2"
}
git_fixup() {
  local COMMIT="${1:-HEAD}"
  git_modified && git commit --fixup="$COMMIT"
  git rebase --interactive --autosquash "${COMMIT}~2"
}

########################################
# Test if remote is using gcrypt
git_gcrypt() {
  for REMOTE; do
    git_url "$REMOTE" | grep '^gcrypt::' >/dev/null && return 0
  done
  false
}

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
# Emulate git checkout --theirs/ours
# http://gitready.com/advanced/2009/02/25/keep-either-file-in-merge-conflicts.html
git_checkout_theirs() {
  git reset -- "$@"
  git checkout MERGE_HEAD -- "$@"
}
git_checkout_ours() {
  git reset -- "$@"
  git checkout ORIG_HEAD -- "$@"
}

########################################
# Prune local branches not in remote anymore
alias git_prune_branches='git remote prune'

# List local tags not in remote at all
git_ls_local_tags() {
  #comm -1 -3 <(git ls-remote --tags origin | cut -d$'\t' -f1 | sort) <(git show-ref --tags | cut -d' ' -f1 | sort)
  PIPE1="$(mktemp -u)"
  mkfifo "$PIPE1"
  PIPE2="$(mktemp -u)"
  mkfifo "$PIPE2"
  comm -2 -3 "$PIPE1" "$PIPE2" | uniq &
  git show-ref --tags | cut -d' ' -f2 | sort -u >"$PIPE1"
  git ls-remote --tags --refs "$@" | cut -d$'\t' -f2 | sort -u >"$PIPE2"
  wait
  rm "$PIPE1" "$PIPE2"
}

# Prune local tags not in remote at all
if ! [ $(git_version) -gt $(git_version 1.7.8) ]; then
  git_prune_local_tags() {
    # Confirmation
    git fetch --dry-run --prune "${@:?No remote specified...}" "+refs/tags/*:refs/tags/*"
    ask_question "Proceed? (y/n) " y Y >/dev/null || return 0
    # Go !
    git fetch --prune "$@" "+refs/tags/*:refs/tags/*"
  }
else
  git_prune_local_tags() {
    # Confirmation
    git_ls_local_tags "$@"
    ask_question "Proceed? (y/n) " y Y >/dev/null || return 0
    # Go !
    git_ls_local_tags "$@" | xargs -r git tag -d
  }
fi

########################################
# Status aliases
alias gt='git status -uno'
alias gtu='gstu'
alias gst='git_st'
alias gstv='git_stx | xargs -0 $GEDITOR'
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
alias gls='git ls-files'
alias glsm='git ls-files -m'
alias glsu='git ls-files -u' # unmerged = in conflict
alias glsd='git ls-files -d'
alias glsn='git ls-files -o --exclude-standard'
alias glsi='git ls-files -o -i --exclude-standard'
# Diff aliases
alias gd='git diff'
alias gdd='git diff'
alias gdm='git difftool -y'
alias gdu='git diff $(git_tracking)'
alias gddu='git diff $(git_tracking)'
alias gdmu='git difftool -y $(git_tracking)'
alias gda='git_diff_all'
alias gdda='git_diff_all'
alias gdma='git_diffm_all'
alias gdc='git diff --cached'
alias gddc='git diff --cached'
alias gdmc='git difftool -y --cached'
alias gdl='git diff --name-only'
alias gdlc='git diff --name-only --cached'
alias gdll='git diff --name-status'
alias gdllc='git diff --name-status --cached'
alias gddr='git diff $(git_tracking)'
alias gdmr='git difftool -y $(git_tracking)'
alias gdcr='git diff --cached $(git_tracking)'
alias gds='git diff stash'
# Diff tree
alias gdta='git diff-tree --diff-filter=A --name-only -r ' #added
alias gdtc='git diff-tree --diff-filter=C --name-only -r ' #copied
alias gdtd='git diff-tree --diff-filter=D --name-only -r ' #deleted
alias gdtm='git diff-tree --diff-filter=M --name-only -r ' #modified
alias gdtr='git diff-tree --diff-filter=R --name-only -r ' #renamed
alias gdtt='git diff-tree --diff-filter=T --name-only -r ' #changed
alias gdtu='git diff-tree --diff-filter=Y --name-only -r ' #unmerged
alias gdtx='git diff-tree --diff-filter=X --name-only -r ' #unknown
alias gdtb='git diff-tree --diff-filter=B --name-only -r ' #broken
# Merge aliases
alias gmm='git mergetool -y'
#alias gmm='gstx UU | xargs -r0 -n1 git mergetool -y'
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
alias gbag='git branch -a | grep'   # list all
alias gblg='git branch -l | grep'   # list local
alias gbvg='git branch -v | grep'   # verbose list local
alias gbvvg='git branch -v | grep'  # double-verbose list local
alias gbvag='git branch -va | grep' # verbose list all
alias gbavg='git branch -va | grep' # verbose list all
alias gbmg='git branch --merged | grep'    # list merged branches
alias gbMg='git branch --no-merged | grep' # list unmerged branches
alias gbrg='git branch -r | grep'   # list remote
alias gbagi='git branch -a | grep -i'   # list all
alias gblgi='git branch -l | grep -i'   # list local
alias gbvgi='git branch -v | grep -i'   # verbose list local
alias gbvvgi='git branch -v | grep -i'  # double-verbose list local
alias gbvagi='git branch -va | grep -i' # verbose list all
alias gbavgi='git branch -va | grep -i' # verbose list all
alias gbmgi='git branch --merged | grep -i'    # list merged branches
alias gbMgi='git branch --no-merged | grep -i' # list unmerged branches
alias gbrgi='git branch -r | grep -i'   # list remote
alias gbd='git branch -d'   # delete branch (merged only)
alias gbD='git branch -D'   # delete branch (any)
alias gbdr='git branch -rd' # remove remote branch (merged only)
alias gbDr='git push :'     # remove remote branch (any)
alias gbdro='git fetch -p'  # remote all old remotes
alias gbu='git branch --set-upstream-to '  # set branch upstream
alias gb='git branch'
alias gst='git_set_tracking'
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
alias gslg='git stash list | grep'
alias gslgi='git stash list | grep -i'
alias gslc='git stash list | wc -l'
alias gsf='git_stash_file'
alias gsfa='git_stash_file_all'
alias gsfc='git_stash_cat'
alias gsd='git_stash_diff'
alias gsd0='git_stash_diff 0'
alias gsdd='git_stash_diff'
alias gsdm='git_stash_diffm'
alias gsdm0='git_stash_diffm 0'
alias gsdl='git_stash_diffl'
alias gsdl0='git_stash_diffl 0'
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
# Hash
alias gha='git_hash'
alias ghar='git_roothash'
# Logs/history aliases
alias gl='git log --oneline'
alias glg='git log --oneline | grep'
alias glgi='git log --oneline | grep -i'
alias gln='git log --oneline -n'
alias gl1='git log --oneline -n 1'
alias gl2='git log --oneline -n 2'
alias gl3='git log --oneline -n 3'
alias gl5='git log --oneline -n 5'
alias gl10='git log --oneline -n 10'
alias glf='git log --follow'
alias gls='git log --stat'
alias glS='git log -S'
alias gla='git shortlog -s -n'
alias glaa='git shortlog -s -n -a'
alias glt='git log --graph'
alias glh='git log -p'
alias glha='git log --pretty=format: --name-only --diff-filter=A | sort -u'
# Reflog
alias grl='git reflog'
alias grl1='git reflog -n 1'
alias grl2='git reflog -n 2'
alias grl3='git reflog -n 3'
alias grl5='git reflog -n 5'
alias grl10='git reflog -n 10'
# Tag aliases
alias gta='git tag -a'
alias gtl='git tag -l'
alias gtlg='git tag -l | grep'
alias gtlgi='git tag -l | grep -i'
alias gtlp='git_tag_list_prev'
alias gtp='git_tag_prev'
alias gtd='git tag -d'
alias gtc='git_tag_create'
alias gtf='git tag --contains'
alias gtls='git log --tags --simplify-by-decoration --pretty="format:%ai %d"'
alias gtda='git tag -l | xargs git tag -d'
alias gtdl='git tag -l | xargs git tag -d; git fetch'
alias gtg='git tag'
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
alias ggp='git grep'
alias ggg='git grep -n'
alias iggg='git grep -ni'
# Checkout aliases
alias gco='git checkout'
#alias gcot='git checkout --theirs'
#alias gcoo='git checkout --ours'
alias gcot='git_checkout_theirs'
alias gcoo='git_checkout_ours'
# Reset aliases
alias gre='git reset'
alias grh='git reset HEAD'
alias grh1='git reset HEAD~'
alias grh2='git reset HEAD~2'
alias grhh='git reset HEAD --hard'
alias gro='git reset $(git_tracking)'
alias grt='git reset $(git_tracking)'
grev() { git reset "$@"; git checkout -- "$@"; }
# Amend last commit
alias gam='git commit --amend'
alias git_amend='git commit --amend'
# Cherry-pick
alias gcp='git cherry-pick'
# Rebase aliases
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbi1='git rebase -i HEAD~1'
alias grbi2='git rebase -i HEAD~2'
alias grbi3='git rebase -i HEAD~3'
alias grbi4='git rebase -i HEAD~4'
alias grbi5='git rebase -i HEAD~5'
alias grbio='git rebase -i $(git_tracking)'
# Fetch/pull/push aliases
alias gpu='git push'
alias gpua='git_push_all'
if [ $(git_version) -gt $(git_version 2.9) ]; then
  alias gup='git pull --rebase --autostash'
elif [ $(git_version) -ge $(git_version 1.7.10.4) ]; then
  alias gup='git pull --rebase'
else
  alias gup='git pull'
fi
alias gfe='git fetch'
alias gfa='git fetch --all --tags'
# Config aliases
alias gcg='git config --get'
alias gcs='git config --set'
alias gcl='git config -l'
alias gcf='git config -l'
alias gcfg='git config -g'
# Git ignore changes
alias git_ignore_changes='git update-index --assume-unchanged'
alias git_noignore_changes='git update-index --no-assume-unchanged'
# gitk aliases
alias gk='gitk'
# ls aliases
alias gls='git_ls'
alias glsg='git_ls | grep'
alias glsc='git_ls_commit'
alias glscg='git_ls_commit | grep'


########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#git}" != "$1" ] && "$@" || true

