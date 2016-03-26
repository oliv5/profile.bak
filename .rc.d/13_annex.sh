#!/bin/sh

# Wrapper: vcsh run
# Overwritten by vcsh main script
command -v "vcsh_run" >/dev/null 2>&1 ||
vcsh_run() {
  eval "$@"
}

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

# Uninit annex
annex_uninit() {
  vcsh_run 'git annex uninit && git config --replace-all core.bare false'
}

# Init annex in direct mode
annex_init_direct() {
  vcsh_run 'annex_init && git annex direct'
}

# Init annex special
annex_init_special() {
  local PREFIX="$1"
  local CMDLINE="$2"
  local REMOTE="${3:-noname}"
  local ENCRYPTION="${4:-none}"
  local REMOTEPATH="${5:-$(git_repo)}"
  shift 5
  local CMDARGS="$(printf "$CMDLINE" "$REMOTE" "$ENCRYPTION" "$REMOTEPATH" "$@")"
  vcsh_run "${PREFIX:+$PREFIX }git annex enableremote $CMDARGS 2>/dev/null || ${PREFIX:+$PREFIX }git annex initremote $CMDARGS"
  #echo $CMDARGS
}

# Init hubic annex
annex_init_hubic() {
  local NAME="${1:-hubic}"; shift
  annex_init_special "" "%s encryption=%s type=external externaltype=hubic hubic_container=annex hubic_path='%s' embedcreds=no" "$NAME" "$@"
}

# Init gdrive annex
annex_init_gdrive() {
  local NAME="${1:-gdrive}"; shift
  annex_init_special "" "%s encryption=%s type=external externaltype=googledrive folder='%s'" "$NAME" "$@"
  local KEY; read -p "Enter the OAUTH key: " KEY
  annex_init_special "OAUTH='$KEY'" "%s encryption=%s type=external externaltype=googledrive folder='%s'" "$NAME" "$@"
}

# Init bup annex
annex_init_bup() {
  local NAME="${1:-bup}"; shift
  annex_init_special "" "%s encryption=%s type=bup buprepo='%s'" "$NAME" "$@"
}

# Init rsync annex
annex_init_rsync() {
  local NAME="${1:-rsync}"; shift
  annex_init_special "" "%s encryption=%s type=rsync rsyncurl='%s' keyid='%s'" "$NAME" "$@"
  git config --add annex.sshcaching false
}

# Init gcrypt annex
annex_init_gcrypt() {
  local NAME="${1:-gcrypt}"; shift
  annex_init_special "" "%s encryption=%s type=gcrypt gitrepo='%s' keyid='%s'" "$NAME" "$@"
}

# Annex sync
annex_sync() {
  vcsh_run 'git annex sync "$@"'
}

# Annex sync content
alias annex_sync_content='annex_sync --content'
alias annex_sync_content_fast='annex_sync --content --fast'

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
  git_exists || return 1
  if annex_exists; then
    local DIR="${1:-$(git_dir)}"
    if [ -d "$DIR" ]; then
      DIR="${1:-$DIR/bundle}"
      local BUNDLE="$DIR/${2:-$(git_name "annex").tgz}"
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

# Annex get
alias annex_get_fast='annex_get --fast'
alias annex_get_auto='annex_get --auto'
alias annex_get='vcsh_run git annex get'

# Annex copy
alias annex_copy_fast='annex_copy --fast'
alias annex_copy_auto='annex_copy --auto'
annex_copy() {
  annex_exists || return 1
  for LAST; do true; done
  if [ "$LAST" = "--from" ] || [ "$LAST" = "--to" ]; then
    for REMOTE in $(git_remotes); do
      vcsh_run git annex copy "$@" "$REMOTE"
    done
  else
    vcsh_run git annex copy "$@"
  fi
}

# Annex download
alias annex_download='annex_copy --from'
alias annex_download_fast='annex_copy_fast --from'

# Annex upload
alias annex_upload='annex_copy --to'
alias annex_upload_fast='annex_copy_fast --to'

# Annex upkeep
annex_upkeep() {
  annex_exists || return 1
  vcsh_run git annex status
  if [ "$1" = "-y" ] || ask_question "Sync new files? (y/n): " y Y >/dev/null; then
    vcsh_run git annex add . --fast
    vcsh_run git annex sync --fast
  fi
  shift
  if [ "$1" = "-y" ] || ask_question "Sync files content? (y/n): " y Y >/dev/null; then
    vcsh_run git annex sync --content --fast
  fi
  shift
  if [ "$1" = "-y" ] || ask_question "Push files content? (y/n): " y Y >/dev/null; then
    vcsh_run git annex copy . --fast --auto
  fi
  if [ "$1" = "-y" ] || ask_question "Pull files content? (y/n): " y Y >/dev/null; then
    vcsh_run git annex get . --fast --auto
  fi
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
