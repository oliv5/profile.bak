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
alias gsb='git_stash_backup'
alias gsrm='git_stash_drop'
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
# Subtree alias
alias gsta='git_subtree_add'
alias gstu='git_subtree_update'
# Git grep aliases
alias ggg='git grep -n'

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
  echo "${GIT_DIR:-$PWD/$(git rev-parse --git-dir)}"
}

# Get git-dir basename
git_repo() {
  local DIR="$(git_dir)"
  [ "${DIR##*/}" != ".git" ] && basename "$DIR" .git || basename "${DIR%/*}" .git
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
  git status -z | awk 'BEGIN{RS="\0"; ORS="\0"}/'"${1:-^[^\?\?]}"'/{print substr($0,4)}'
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

# Meld called by git
git_meld() {
  meld "$2" "$5"
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
  git stash pop "stash@{${1:-0}}"
}

# Apply change from stash
git_stash_apply() {
  git stash apply "stash@{${1:-0}}"
}

# Show diff between stash and local copy
git_stash_diff() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git diff "stash@{$STASH}" "$@"
}
git_stash_diffm() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git_diffm "stash@{$STASH}" "$@" 
}
git_stash_diffl() {
  git_stash_diff "${@:-0}" --name-only
}

# Show stash file list
git_stash_show() {
  local STASH="${1:-0}"; shift $(min 1 $#)
  git stash show "stash@{$STASH}" "$@"
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
  git stash show -p "stash@{$STASH}" "$@"
}

# Drop a stash
git_stash_drop() {
  local STASH="${1:-0}"; shift $(min 1 $#)
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
    for DESCR in $(git stash list --pretty=format:"%h %gd %ci"); do
      local NAME="$(echo $DESCR | awk '{gsub(/-/,"",$3); gsub(/:/,"",$4); print "stash{" $3 "-" $4 "}_" $1}')"
      local FILE="$DST/${NAME}.gz"
      if [ ! -e "$FILE" ]; then
        local STASH="$(echo $DESCR | awk '{print $2}')"
        echo "Backup $STASH in $FILE"
        git stash show -p "$STASH" "$@" | gzip --best > "$FILE"
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
# Remove things
alias git_rm_tracking_branch='git branch -dr'
alias git_rm_tracking_branch2='git fetch -p'
alias git_rm_remote_branch='push origin -d'
alias git_rm_branch='git branch -d'

########################################
# https://stackoverflow.com/questions/4479960/git-checkout-to-a-specific-folder
# Export the whole repo
git_export() {
  local DST="${1:?No output directory specified}"
  shift
  # The last '/' is important
  git checkout-index -a -f --prefix="$DST/" "$@"
}

# Export a directory
git_exportdir() {
  local DST="${1:?No output directory specified}"
  local SRC="${2:?No input directory specified}"
  shift 2
  # The last '/' is important
  find "$SRC" -print0 | git checkout-index --prefix="$DST/" "$@" -f -z --stdin
}

########################################
# Batch clone
git_clone() {
	local REPO="$(git_repo)"
	for ARGS; do
		set $ARGS
		local REMOTE="${1:?No remote specified}"
		local NAME="${2:-$REPO}"
		local BRANCH="${3:-master}"
		git clone "$REMOTE" "$REPO" || break
		git --git-dir="$REPO/.git" remote rename origin "$NAME"
		git --git-dir="$REPO/.git" checkout "$BRANCH"
	done
}

########################################
# Batch pull
# Use vcsh wrapper when necessary
git_pull() {
	local REMOTES="${1:?No remote specified}"
	local BRANCHES="${2:-master}"
	local STASH="__git_pull_stash"
	vcsh_run "
		git stash save -q \"$STASH\"
		for REMOTE in $REMOTES; do
			if git remote | grep -- \"\$REMOTE\" >/dev/null; then
				for BRANCH in $BRANCHES; do
					git pull --rebase \"\$REMOTE\" \"\$BRANCH\"
				done
			fi
		done
		if git stash list -n 1 | grep \"$STASH\" >/dev/null 2>&1; then
			git stash apply -q --index
			git stash drop -q
		fi
	"
}

########################################
# Batch push
git_push() {
	local REMOTES="${1:?No remote specified}"
	local BRANCHES="${2:-master}"
	for REMOTE in $REMOTES; do
		if git remote | grep -- "$REMOTE" >/dev/null; then
			for BRANCH in $BRANCHES; do
				echo -n "Push $REMOTE/$BRANCH : "
				git push "$REMOTE" "$BRANCH"
			done
		fi
	done
}

########################################
# Create a bundle
git_bundle() {
	local DIR="${1:-$(git_dir)}"
	if [ -d "$DIR" ]; then
    DIR="${1:-$DIR/bundle}"
		local BUNDLE="$DIR/${2:-bundle.$(uname -n).$(git_repo).$(git_branch).$(date +%Y%m%d-%H%M%S).$(git_shorthash).git}"
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

########################################
# Check annex exists
annex_exists() {
  git ${1:+--git-dir="$1"} config --get annex.version >/dev/null 2>&1
}

# Check annex has been modified
annex_modified() {
  test ! -z "$(git ${1:+--git-dir="$1"} annex status)"
}

# Test annex direct-mode
annex_direct() {
	[ "$(git ${1:+--git-dir="$1"} config --get annex.direct)" = "true" ]
}

# Test annex bare
annex_bare() {
	annex_exists && ! annex_direct && git_bare
}

# Init annex
annex_init() {
	vcsh_run 'git annex init "$(uname -n)"'
}

# Init annex in direct mode
annex_init_direct() {
	vcsh_run 'annex_init && git annex direct'
}

# Init hubic annex
annex_init_hubic() {
	local REMOTE="${1:-hubic}"
	local HUBIC_PATH="${2:-$(git_repo)}"
	vcsh_run "
		git annex enableremote \"$REMOTE\" type=external externaltype=hubic encryption=none hubic_container=annex hubic_path=\"$HUBIC_PATH\" embedcreds=no ||
		git annex initremote \"$REMOTE\" type=external externaltype=hubic encryption=none hubic_container=annex hubic_path=\"$HUBIC_PATH\" embedcreds=no
	"
}

# Annex sync
annex_sync() {
	vcsh_run 'git annex sync'
}

# Annex status
annex_status() {
	echo "annex status:"
	vcsh_run 'git annex status'
}

# Annex diff
annex_diff() {
	if ! annex_direct; then
		vcsh_run 'git diff' "$@"
	fi
}

# Annex bundle
annex_bundle() {
	if annex_exists; then
    local DIR="${1:-$(git_dir)}"
    if [ -d "$DIR" ]; then
      DIR="${1:-$DIR/bundle}"
      local BUNDLE="$DIR/${2:-annex.$(uname -n).$(git_repo).$(git_branch).$(date +%Y%m%d-%H%M%S).$(git_shorthash).git}"
      local GPG_RECIPIENT="$3"
			echo "Tar annex into $BUNDLE"
			if annex_bare; then
				tar cf "${BUNDLE}" -h ./annex
			else
				vcsh_run "git annex list $(git config --get core.worktree)" | 
					awk 'NF>1 {$1="";print "\""substr($0,2)"\""}' |
					xargs tar cf "${BUNDLE}" -h --exclude-vcs
			fi
			if [ ! -z "$GPG_RECIPIENT" ]; then
				gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" "${BUNDLE}" && 
					(shred -fu "${BUNDLE}" || wipe -f -- "${BUNDLE}" || rm -- "${BUNDLE}")
			fi
			ls -l "${BUNDLE}"*
		else
			echo "Target directory '$DIR' does not exists."
			echo "Skip bundle creation..."
		fi
	else
		echo "Repository '$(git_dir)' is not git-annex ready."
		echo "Skip bundle creation..."
	fi
}

# Annex copy
annex_copy() {
	vcsh_run 'git annex copy' "$@"
}

########################################
# Repo vcsh-ready
vcsh_exists() {
	git ${1:+--git-dir="$1"} config --get vcsh.vcsh >/dev/null 2>&1
}

# vcsh loaded
vcsh_loaded() {
  [ ! -z "$VCSH_REPO_NAME" ]
}

# Batch clone
vcsh_clone() {
	local REPO="$(git_repo)"
	for ARGS; do
		set $ARGS
		local REMOTE="${1:?No remote specified}"
		local NAME="${2:-$REPO}"
		local BRANCH="${3:-master}"
    vcsh clone "$REMOTE" "$REPO" || break
    vcsh run "$REPO" git remote rename origin "$NAME"
    vcsh run "$REPO" git checkout "$BRANCH"
	done
}

# Run a git command, call vcsh when necessary
vcsh_run() {
  if [ $# -le 1 ]; then
    local ARGS="$1"
  else    
    local ARGS="$(
      arg_quote() {
        local SEP=''
        for ARG; do
          SQESC=$(printf '%s\n' "${ARG}" | sed -e "s/'/'\\\\''/g")
          printf '%s' "${SEP}'${SQESC}'"
          SEP=' '
        done
      }
      arg_quote "$@"
    )"
  fi
  if vcsh_exists; then
    vcsh run "$(git_repo)" sh -c "$ARGS"
  else
    sh -c "$ARGS"
  fi
}

########################################
# Batch bundle repos
repo_bundle() {
  local ARGS="\"$1\" \"$2\" \"$3\""
  shift 3 2>/dev/null
  eval repo forall "\"$@\"" -c git_bundle "$ARGS"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
