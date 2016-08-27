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

# Init hubic annex
annex_init_hubic() {
  local NAME="${1:-hubic}"
  local ENCRYPTION="${2:-none}"
  local REMOTEPATH="${3:-$(git_repo)}"
  local KEYID="$4"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=hubic hubic_container=annex hubic_path="$REMOTEPATH" embedcreds=no keyid+="$KEYID" ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=external externaltype=hubic hubic_container=annex hubic_path="$REMOTEPATH" embedcreds=no keyid="$KEYID" 
}

# Init gdrive annex
annex_init_gdrive() {
  local NAME="${1:-gdrive}"
  local ENCRYPTION="${2:-none}"
  local REMOTEPATH="${3:-$(git_repo)}"
  local KEYID="$4"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=googledrive folder="$REMOTEPATH" keyid+="$KEYID" ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=external externaltype=googledrive folder="$REMOTEPATH" keyid="$KEYID" 
}

# Init bup annex
annex_init_bup() {
  local NAME="${1:-bup}"
  local ENCRYPTION="${2:-none}"
  local REMOTEPATH="${3:-$(git_repo)}"
  local KEYID="$4"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=bup buprepo="$REMOTEPATH" keyid+="$KEYID" ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=bup buprepo="$REMOTEPATH" keyid="$KEYID" 
}

# Init rsync annex
annex_init_rsync() {
  local NAME="${1:-rsync}"
  local ENCRYPTION="${2:-none}"
  local REMOTEPATH="${3:-$(git_repo)}"
  local KEYID="$4"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=rsync rsyncurl="$REMOTEPATH" keyid+="$KEYID" ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=rsync rsyncurl="$REMOTEPATH" keyid="$KEYID"
  git config --add annex.sshcaching false
}

# Init gcrypt annex
annex_init_gcrypt() {
  local NAME="${1:-gcrypt}"
  local ENCRYPTION="${2:-none}"
  local REMOTEPATH="${3:-$(git_repo)}"
  local KEYID="$4"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=gcrypt gitrepo="$REMOTEPATH" keyid+="$KEYID" ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=gcrypt gitrepo="$REMOTEPATH" keyid="$KEYID"
  git config --add annex.sshcaching false
}

#~ # Init annex special
#~ annex_init_special() {
  #~ local PREFIX="$1"
  #~ local CMDLINE="$2"
  #~ local REMOTE="${3:-noname}"
  #~ local ENCRYPTION="${4:-none}"
  #~ local REMOTEPATH="${5:-$(git_repo)}"
  #~ shift 5
  #~ local CMDARGS="$(printf "$CMDLINE" "$REMOTE" "$ENCRYPTION" "$REMOTEPATH" "$@")"
  #~ vcsh_run "${PREFIX:+$PREFIX }git annex enableremote $CMDARGS 2>/dev/null || ${PREFIX:+$PREFIX }git annex initremote $CMDARGS"
  #~ #echo $CMDARGS
#~ }

#~ # Init hubic annex
#~ annex_init_hubic() {
  #~ local NAME="${1:-hubic}"; shift
  #~ annex_init_special "" "%s encryption=%s type=external externaltype=hubic hubic_container=annex hubic_path='%s' embedcreds=no" "$NAME" "$@"
#~ }

#~ # Init gdrive annex
#~ annex_init_gdrive() {
  #~ local NAME="${1:-gdrive}"; shift
  #~ annex_init_special "" "%s encryption=%s type=external externaltype=googledrive folder='%s'" "$NAME" "$@"
  #~ local KEY; read -p "Enter the OAUTH key: " KEY
  #~ annex_init_special "OAUTH='$KEY'" "%s encryption=%s type=external externaltype=googledrive folder='%s'" "$NAME" "$@"
#~ }

#~ # Init bup annex
#~ annex_init_bup() {
  #~ local NAME="${1:-bup}"; shift
  #~ annex_init_special "" "%s encryption=%s type=bup buprepo='%s'" "$NAME" "$@"
#~ }

#~ # Init rsync annex
#~ annex_init_rsync() {
  #~ local NAME="${1:-rsync}"; shift
  #~ annex_init_special "" "%s encryption=%s type=rsync rsyncurl='%s' keyid='%s'" "$NAME" "$@"
  #~ git config --add annex.sshcaching false
#~ }

#~ # Init gcrypt annex
#~ annex_init_gcrypt() {
  #~ local NAME="${1:-gcrypt}"; shift
  #~ annex_init_special "" "%s encryption=%s type=gcrypt gitrepo='%s' keyid='%s'" "$NAME" "$@"
#~ }

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

# Git status for scripts
annex_st() {
  vcsh_run 'git annex status' | awk '/^[\? ]?'$1'[\? ]?/ {print "\""$2"\""}'
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
    local DIR="${1:-$(git_dir)/bundle}"
    if [ -d "$DIR" ]; then
      local BUNDLE="$DIR/${2:-$(git_name "annex").tgz}"
      local GPG_RECIPIENT="$3"
      local GPG_TRUST="${4:+--trust-model always}"
      echo "Tar annex into $BUNDLE"
      if annex_bare; then
        tar cf "${BUNDLE}" -h ./annex
      else
        vcsh_run "git annex list $(git config --get core.worktree)" | 
          awk 'NF>1 {$1="";print "\""substr($0,2)"\""}' |
          xargs tar cf "${BUNDLE}" -h --exclude-vcs --
      fi
      if [ ! -z "$GPG_RECIPIENT" ]; then
        gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${BUNDLE}" &&
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
alias annex_get_auto='annex_get --auto'
alias annex_get_fast='annex_get --fast'
alias annex_get_fast_auto='annex_get --fast --auto'
alias annex_get_missing='annex_missing | xargs annex_get'
alias annex_get='vcsh_run git annex get'

# Annex copy
alias annex_copy_all='annex_copy --all'
alias annex_copy_auto='annex_copy --auto'
alias annex_copy_fast='annex_copy --fast'
alias annex_copy_fast_auto='annex_copy --fast --auto'
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
alias annex_download_all='annex_copy_all --from'
alias annex_download_auto='annex_copy_auto --from'

# Annex upload
alias annex_upload='annex_copy --to'
alias annex_upload_fast='annex_copy_fast --to'
alias annex_upload_all='annex_copy_all --to'
alias annex_upload_auto='annex_copy_auto --to'

# Annex upkeep
annex_upkeep() {
  annex_exists || return 1
  # Get args
  local ADD=""
  local SYNC=""
  local DL=""
  local UL=""
  local MSG="[upkeep] auto-commit"
  local FLAG OPTIND OPTARG
  while getopts "vasdum" FLAG; do
    case "$FLAG" in
      v) vcsh_run git annex status;;
      a) ADD=1; annex_direct && SYNC=1;;
      s) SYNC=1;;
      d) DL=1;;
      u) UL=1;;
      m) MSG="$OPTARG";;
    esac
  done
  # Run
  if [ -n "$ADD" ]; then
    vcsh_run git annex add . --fast
    if ! annex_direct; then
      vcsh_run git commit -m "$MSG"
    fi
  fi
  if [ -n "$SYNC" ]; then
    vcsh_run git annex sync
  fi
  if [ -n "$DL" ]; then
    vcsh_run git annex get
  fi
  if [ -n "$UL" ]; then
    annex_upload_fast
  fi
}

# Find aliases
alias annex_wantget='git annex find --want-get --not --in'
alias annex_wantdrop='git annex find --want-drop --in'
alias annex_present='git annex find'
alias annex_absent='git annex find --not --in=here'
alias annex_missing='git annex list | grep "^_+ "'

# Find annex repositories
annex_find() {
	ff_git0 "${1:-.}" |
		while read -d $'\0' DIR; do
			annex_exists "$DIR" && printf "'%s'\n" "$DIR"
		done 
}

# Fsck/check all
alias annex_fsck='annex_find | xargs -I {} -n 1 sh -c "cd \"{}/..\"; pwd; git annex fsck"'
alias annex_check='annex_find | xargs -I {} -n 1 sh -c "cd \"{}/..\"; pwd; git annex list | grep \"^_\""'

# Rename special remotes
annex_rename_special() {
	git config remote.$1.fetch dummy
	git remote rename "$1" "$2"
	git config --unset remote.$2.fetch
	git annex initremote "$1" name="$2"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
