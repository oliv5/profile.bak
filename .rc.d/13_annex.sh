#!/bin/sh

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
  local RPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local CMDARGS="\"$REMOTE\" type=external externaltype=hubic encryption=\"$ENCRYPTION\" hubic_container=annex hubic_path=\"$RPATH\" embedcreds=no"
  vcsh_run "git annex enableremote $CMDARGS || git annex initremote $CMDARGS"
}

# Init gdrive annex
annex_init_gdrive() {
  local REMOTE="${1:-gdrive}"
  local RPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local CMDARGS="git annex enableremote \"$REMOTE\" type=external externaltype=googledrive encryption=\"$ENCRYPTION\" folder=\"$RPATH\""
  vcsh_run "git annex enableremote $CMDARGS || git annex initremote $CMDARGS"
  local KEY; read -p "Enter the OAUTH key: " KEY
  vcsh_run "OAUTH='$KEY' git annex enableremote $CMDARGS || OAUTH='$KEY' git annex initremote $CMDARGS"
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
      local BUNDLE="$DIR/${2:-annex.$(git_name).git}"
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
