#!/bin/sh

# Annex aliases
alias gana='git annex add'
alias gant='git annex status'
alias ganst='git annex status'
alias ganl='git annex list'
alias ganls='git annex list'
alias ganlc='git annex find | wc -l'
alias ganf='git annex find'
alias ganfc='git annex find | wc -l'
alias gans='git annex sync'
alias gansn='git annex sync --no-commit'
alias gansp='git annex sync --no-commit --no-push'
alias gansu='git annex sync --no-commit --no-pull'
alias gansc='git annex sync --content'
alias ganscf='git annex sync --content --fast'
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
alias gan='git annex'

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
  annex_exists "$@" && ! annex_direct "$@" && git_bare "$@"
}

# Test annex standard (indirect, not bare)
annex_std() {
  annex_exists "$@" && ! annex_direct "$@" && ! git_bare "$@"
}

# Init annex
annex_init() {
  git init "$1" && git annex init "${2:-$(uname -n)}"
}

# Init annex bare repo
annex_init_bare() {
  git init --bare "$1" && git annex init "${2:-$(uname -n)}"
}

# Uninit annex
annex_uninit() {
  git annex uninit && git config --replace-all core.bare false
}

# Init annex in direct mode
annex_init_direct() {
  annex_init && git annex direct
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

# Git status for scripts
annex_st() {
  git annex status | awk -F'#;#.' '/^[\? ]?'$1'[\? ]?/ {sub(/ /,"#;#.");print $2}'
}

# Annex diff
annex_diff() {
  if ! annex_direct; then
    git diff "$@"
  fi
}

# Get remote(s) uuid
annex_uuid() {
  for REMOTE in "${@:-.*}"; do
    git config --get-regexp remote\.${REMOTE}\.annex-uuid
  done
}

# List annexed remotes
annex_remotes() {
  git config --get-regexp "remote\..*\.annex-uuid" |
    awk -F. '{print $2}' | xargs
}

# List annexed enabled remotes
annex_enabled() {
  local EXCLUDE="$(git config --get-regexp "remote\..*\.annex-ignore" true | awk -F. '{printf $2"|"}' | sed -e "s/|$//")"
  git config --get-regexp "remote\..*\.annex-uuid" |
    grep -vE "${EXCLUDE:-$^}" | 
    awk -F. '{print $2}' | xargs
}

# Annex bundle
annex_bundle() {
  ( set +e; # Need to go on
  git_exists || return 1
  if annex_exists; then
    local DIR="${1:-$(git_dir)/bundle}"
    mkdir -p "$DIR"
    if [ -d "$DIR" ]; then
      local BUNDLE="$DIR/${2:-$(git_name "annex").tgz}"
      local GPG_RECIPIENT="$3"
      local GPG_TRUST="${4:+--trust-model always}"
      echo "Tar annex into $BUNDLE"
      if annex_bare; then
        tar zcf "${BUNDLE}" --exclude='*/creds/*' -h ./annex
      else
        git annex find | 
          awk '{print "\""$0"\""}' |
          xargs -r tar zcf "${BUNDLE}" -h --exclude-vcs --
      fi
      if [ ! -z "$GPG_RECIPIENT" ]; then
        gpg -v --output "${BUNDLE}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${BUNDLE}" &&
          (shred -fu "${BUNDLE}" || wipe -f -- "${BUNDLE}" || rm -- "${BUNDLE}")
      fi
      ls -l "${BUNDLE}"*
    else
      echo "Output directory '$DIR' cannot be created."
      echo "Skip bundle creation..."
      exit 1
    fi
  else
    echo "Repository '$(git_dir)' is not git-annex ready."
    echo "Skip bundle creation..."
    exit 1
  fi
  )
}

# Annex enumeration
annex_enum() {
  ( set +e; # Need to go on
  git_exists || return 1
  if annex_std; then
    local DIR="${1:-$(git_dir)/list}"
    mkdir -p "$DIR"
    if [ -d "$DIR" ]; then
      local LIST="$DIR/${2:-$(git_name "annex.enum").txt.gz}"
      local GPG_RECIPIENT="$3"
      local GPG_TRUST="${4:+--trust-model always}"
      echo "List annex into $LIST"
      git annex find "$(git_root)" --in . --or --not --in . --print0 | xargs -r0 -n1 sh -c '
        LIST="$1"; FILE="$2"
        printf "\"%s\" <- \"%s\"\n" "$(readlink -- "$FILE")" "$FILE" | grep -F ".git/annex" >> "${LIST%.*}"
      ' _ "$LIST"
      if [ -r "${LIST%.*}" ]; then
        gzip -S .gz -9 "${LIST%.*}"
        if [ ! -z "$GPG_RECIPIENT" ]; then
          gpg -v --output "${LIST}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${LIST}" &&
            (shred -fu "${LIST}" || wipe -f -- "${LIST}" || rm -- "${LIST}")
        fi
        ls -l "${LIST}"*
      else
        echo "Listing is missing or empty."
        echo "Skip list creation..."
        exit 1
      fi
    else
      echo "Output directory '$DIR' cannot be created."
      echo "Skip list creation..."
      exit 1
    fi
  else
    echo "Repository '$(git_dir)' cannot be enumerated."
    echo "Skip list creation..."
    exit 1
  fi
  )
}

# Annex copy
alias annex_copy_all='annex_copy --all'
alias annex_copy_auto='annex_copy --auto'
alias annex_copy_fast='annex_copy --fast'
alias annex_copy_fast_auto='annex_copy --fast --auto'
annex_copy() {
  annex_exists || return 1
  for LAST; do true; done
  if [ "$LAST" = "--from" ] || [ "$LAST" = "--to" ]; then
    for REMOTE in $(annex_enabled); do
      git annex copy "$@" "$REMOTE"
    done
  else
    git annex copy "$@"
  fi
}

# Annex download
alias annex_download='annex_copy --from'
alias annex_download_fast='annex_copy_fast --from'
alias annex_download_all='annex_copy_all --from'
alias annex_download_auto='annex_copy_auto --from'
alias annex_download_fast_auto='annex_copy_fast_auto --from'

# Annex upload
alias annex_upload='annex_copy --to'
alias annex_upload_fast='annex_copy_fast --to'
alias annex_upload_all='annex_copy_all --to'
alias annex_upload_auto='annex_copy_auto --to'
alias annex_upload_fast_auto='annex_copy_fast_auto --to'

# Transfer files to the specified repos, one by one
# $FROM is used to selected the origin repo
# $DROP is used to drop the newly retrieved files
# $DBG is used to print the command on stderr
alias annex_transfer='DBG= DROP=1 _annex_transfer'
alias annex_move='DBG= DROP=2 _annex_transfer'
_annex_transfer() {
  annex_exists || return 1
  local REPOS="${1:-$(annex_enabled)}"
  local DBG="${DBG:+echo}"
  [ $# -gt 0 ] && shift
  [ -z "$REPOS" ] && return 0
  # Copy local files to remote repos
  local IFS=$' '
  for REPO in $REPOS; do
    while ! $DBG git annex copy --not --in "$REPO" --to "$REPO" "$@"; do true; done
  done
  [ "$DROP" = "2" ] && $DBG git annex drop --in . "$@"
  # Get/copy/drop all missing local files
  local LOCATION="$(echo "$REPOS" | sed -e 's/ / --or --not --in /g')"
  git annex find --not --in . --and -\( --not --in $LOCATION -\) --print0 "$@" | xargs -r0 -n1 sh -c '
    REPOS="$1";F="$2"
    $DBG git annex get ${FROM:+--from "$FROM"} "$F" || exit $?
    for REPO in $REPOS; do
      while ! $DBG git annex copy --not --in "$REPO" --to "$REPO" "$F"; do true; done
    done
    [ -n "$DROP" ] && $DBG git annex drop "$F"
    exit 0
  ' _ "$REPOS"
}

# Rsync files to the specified location, one by one
# $FROM is used to selected the origin repo
# $DROP is used to drop the newly retrieved files
# $DBG is used to print the command on stderr
# $DELETE is used to delete the missing existing files
alias annex_rsync='DBG= DELETE= DROP=1 _annex_rsync'
alias annex_rsyncd='DBG= DELETE=2 DROP=1 _annex_rsync'
alias annex_rsyncds='DBG= DELETE=1 DROP=1 _annex_rsync'
_annex_rsync() {
  annex_exists || return 1
  local DST="${1:?No destination specified...}"
  local SRC="${PWD}"
  local DBG="${DBG:+echo}"
  local RSYNC_OPT="-v -r -z -s -i --inplace --size-only --progress -K -L -P --exclude=.git/"
  [ $# -gt 0 ] && shift
  [ "${SRC%/}" = "${DST%/}" ] && return 2
  # Copy local files
  for F in "${@:-}"; do
    if [ -d "$SRC/$F" ]; then
      while ! $DBG rsync $RSYNC_OPT "$SRC/${F:+$F/}" "$DST/${F:+$F/}"; do true; done
    else
      while ! $DBG rsync $RSYNC_OPT "$SRC/$F" "$(dirname "$DST/$F")/"; do true; done
    fi
  done
  [ "$DROP" = "2" ] && $DBG git annex drop --in . "$@"
  # Get/copy/drop all missing local files
  local TMPFILE="$(tempfile)"
  git annex find --not --in . --print0 "$@" | xargs -r0 -n1 sh -c '
    DBG="$1²";RSYNC_OPT="$2";TMPFILE="$3";DST="$4/$5";SRC="$5"
    if [ -n "$(rsync -ni --ignore-existing "$TMPFILE" "$DST")" ]; then
      $DBG git annex get ${FROM:+--from "$FROM"} "$SRC" || exit $?
      while ! $DBG rsync $RSYNC_OPT "$SRC" "$(dirname "$DST")/"; do true; done
      [ -n "$DROP" ] && $DBG git annex drop "$SRC"
      exit 0
    fi
  ' _ "$DBG" "$RSYNC_OPT" "$TMPFILE" "$DST"
  # Delete missing destination files
  if [ "$DELETE" = 1 ]; then
    while ! $DBG rsync -rni --delete --cvs-exclude --ignore-existing --ignore-non-existing "$SRC" "$DST"; do true; done
  elif [ "$DELETE" = 2 ]; then
    while ! $DBG rsync -ri --delete --cvs-exclude --ignore-existing --ignore-non-existing "$SRC" "$DST"; do true; done
  fi
}

# Drop local files which are in the specified remote repos
alias annex_drop='git annex drop -N $(annex_enabled | wc -w)'
annex_drop_fast() {
  annex_exists || return 1
  local REPOS="${1:-$(annex_enabled)}"
  local COPIES="$(echo "$REPOS" | wc -w)"
  local LOCATION="$(echo "$REPOS" | sed -e 's/ / --and --in /g')"
  [ $# -gt 0 ] && shift
  git annex drop --in $LOCATION -N "$COPIES" "$@"
}

# Annex upkeep
annex_upkeep() {
  local DBG=""
  # Add options
  local ADD=""
  local DEL=""
  # Sync options
  local MSG="annex_upkeep() at $(date)"
  local SYNC=""
  local SYNC_OPT="--no-commit --no-pull --no-push"
  # Copy options
  local GET=""
  local GET_OPT=""
  local SEND=""
  local SEND_OPT="--all"
  local REMOTES="$(annex_enabled)"
  # Get arguments
  #echo "[annex_upkeep] arguments: $@"
  while getopts "adscpum:ger:ftzh" OPTFLAG; do
    case "$OPTFLAG" in
      # Add
      a) ADD=1;;
      d) DEL=1;;
      # Sync
      s) SYNC=1; SYNC_OPT="--commit --pull --push";;
      c) SYNC=1; SYNC_OPT="${SYNC_OPT%--no-commit*} ${SYNC_OPT#*--no-commit} --commit";;
      p) SYNC=1; SYNC_OPT="${SYNC_OPT%--no-pull*} ${SYNC_OPT#*--no-pull} --pull";;
      u) SYNC=1; SYNC_OPT="${SYNC_OPT%--no-push*} ${SYNC_OPT#*--no-push} --push";;
      t) SYNC=1; SYNC_OPT="${SYNC_OPT} --content";;
      m) MSG="${OPTARG}";;
      # UL/DL
      g) GET=1;;
      e) SEND=1;;
      r) REMOTES="${OPTARG}";;
      f) GET_OPT="--fast"; SEND_OPT="--fast";;
      # Misc
      z) set -vx; DBG="true";;
      *) echo >&2 "Usage: annex_upkeep [-a] [-d] [-s] [-c] [-m 'msg'] [-p] [-u] [-g] [-e] [-r 'remote1 remote2 ..'] [-f] [-z]"
         echo >&2 "-a (a)dd new files"
         echo >&2 "-d add (d)eleted files"
         echo >&2 "-s (s)ync"
         echo >&2 "-c (c)ommit"
         echo >&2 "-p (p)ull"
         echo >&2 "-u p(u)sh"
         echo >&2 "-m (m)essage"
         echo >&2 "-g (g)et"
         echo >&2 "-e s(e)nd to remotes"
         echo >&2 "-f (f)ast get/send"
         echo >&2 "-t sync conten(t)"
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
  annex_exists || return 1
  #echo "[annex_upkeep] start at $(date)"
  # Add
  if [ -n "$ADD" ]; then
    $DBG git annex add . || return $?
  fi
  # Revert deleted files
  if [ -z "$DEL" ] && ! annex_direct; then
    gstx D | xargs -r0 $DBG git checkout || return $?
    #annex_st D | xargs -r $DBG git checkout || return $?
  fi
  # Sync
  if [ -n "$SYNC" ]; then
    $DBG git annex sync --message="$MSG" $SYNC_OPT || return $?
  fi
  # Get
  if [ -n "$GET" ]; then
      $DBG git annex get $GET_OPT || return $?
  fi
  # Upload
  if [ -n "$SEND" ]; then
    [ -z "$REMOTES" ] && echo "No remotes to send to..." && return 1
    for REMOTE in ${REMOTES}; do
      $DBG git annex copy --to "$REMOTE" $SEND_OPT || return $?
    done
  fi
  #echo "[annex_upkeep] end at $(date)"
}

# Find aliases
alias annex_existing='git annex find --in'
alias annex_missing='git annex find --not --in'
alias annex_wantget='git annex find --want-get --not --in'
alias annex_wantdrop='git annex find --want-drop --in'
annex_lost() { git annex list "$@" | grep -E "^_+ "; }

# Is file in annex ?
annex_isin() {
  annex_exists || return 1
  local REPO="${1:-.}"
  shift
  [ -n "$(git annex find --in "$REPO" "$@")" ]
}

# Find annex repositories
annex_find_repo() {
	ff_git0 "${1:-.}" |
		while read -d $'\0' DIR; do
			annex_exists "$DIR" && printf "'%s'\n" "$DIR"
		done 
}

# Fsck/check all
alias annex_fsck='annex_find_repo | xargs -r -I {} -n 1 sh -c "cd \"{}/..\"; pwd; git annex fsck"'
alias annex_check='annex_find_repo | xargs -r -I {} -n 1 sh -c "cd \"{}/..\"; pwd; git annex list | grep \"^_\""'

# Rename special remotes
annex_rename_special() {
	git config remote.$1.fetch dummy
	git remote rename "$1" "$2"
	git config --unset remote.$2.fetch
	git annex initremote "$1" name="$2"
}

# Revert changes in all modes (indirect/direct)
annex_revert() {
  git annex proxy -- git revert "${1:-HEAD}"
}

# Annex info
alias annex_du='git annex info --fast'

########################################
# Find files from key
# Note key = file content, so there can be
# multiple files mapped to a single key
annex_fromkey() {
  for KEY; do
    #git show -999999 -p --no-color --word-diff=porcelain -S "$KEY" | 
    git log -p --no-color --word-diff=porcelain -S "$KEY" | 
      awk '/^(---|\+\+\+) (a|b)/{line=$0} /'$KEY'/{printf "%s\0",substr(line,5); exit 0}' |
      # Remove leading/trailing double quotes, leading "a/", trailing spaces.
      # Escape '%'
      sed -z -e 's/\s*$//' -e 's/^"//' -e 's/"$//' -e 's/^..//' -e 's/%/\%/g' |
      # printf does evaluate octal charaters from UTF8
      xargs -r0 -n1 -I {} -- printf "{}\0"
      # Sanity extension check between key and file
      #xargs -r0 -n1 sh -c '
        #[ "${1##*.}" != "${2##*.}" ] && printf "Warning: key extension ${2##*.} mismatch %s\n" "${1##*/}" >&2
        #printf "$2\0"
      #' _ "$KEY"
  done
}

# List unused files matching pattern
annex_unused() {
  ! annex_bare || return 1
  local PATTERNS=""
  for ARG; do PATTERNS="${PATTERNS:+$PATTERNS }-e '$ARG'"; done
  eval annex_fromkey $(git annex unused ${FROM:+--from $FROM} | awk "/^\s+[0-9]+\s/{print \$2}") ${PATTERNS:+| grep -zF $PATTERNS} | xargs -r0 -n1
}

# Drop unused files matching pattern
annex_dropunused() {
  ! annex_bare || return 1
  local IFS="$(printf ' \t\n')"
  local PATTERNS=""
  for ARG; do PATTERNS="${PATTERNS:+$PATTERNS }-e '$ARG'"; done
  git annex unused ${FROM:+--from $FROM} | grep -E '^\s+[0-9]+\s' | 
    while IFS=' ' read -r NUM KEY; do
      eval annex_fromkey "$KEY" ${PATTERNS:+| grep -zF $PATTERNS} | xargs -r0 sh -c '
        NUM="$1";KEY="$2"; shift 2
        for FILE; do
          printf "Drop unused file %s\nFile: %s\nKey: %s\n" "$NUM" "$FILE" "$KEY"
        done
        git annex dropunused "$NUM" ${FROM:+--from $FROM} ${FORCE:+--force}
        echo ""
      ' _ "$NUM" "$KEY"
    done
}

# Drop all unused files interactively
annex_dropunused_interactive() {
  ! annex_bare || return 1
  local IFS="$(printf ' \t\n')"
  local REPLY; read -r -p "Delete unused files? (a/y/n/s) " REPLY
  if [ "$REPLY" = "a" -o "$REPLY" = "A" ]; then
    local LAST="$(git annex unused | awk '/SHA256E/ {a=$1} END{print a}')"
    git annex dropunused "$@" 1-$LAST
  elif [ "$REPLY" = "s" -o "$REPLY" = "S" ]; then
    annex_show_unused_key
  elif [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
    local LAST="$(git annex unused | awk '/SHA256E/ {a=$1} END{print a}')"
    git annex unused | grep -F 'SHA256E' | 
      while read -r NUM KEY; do
        printf "Key: $KEY\nFile: "
        annex_fromkey "$KEY"
        echo
        read -r -p "Delete file $NUM/$LAST? (y/f/n) " REPLY < /dev/tty
        if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
          sh -c "git annex dropunused ""$@"" $NUM" &
          wait
        elif [ "$REPLY" = "f" -o "$REPLY" = "F" ]; then
          sh -c "git annex dropunused --force ""$@"" $NUM" &
          wait
        fi
        echo "~"
      done
  fi
}

# Clean log by rebuilding branch git-annex & master
# Similar to "git annex forget"
annex_forget() {
  # Stop on error
  ( set -e
    annex_exists || return 1
    if [ $(git_st | wc -l) -ne 0 ]; then
      echo "Some changes are pending. Abort ..."
      return 2
    fi
    # Confirmation
    read -r -p "Delete file $NUM ($KEY)? (y/n) " REPLY < /dev/tty
    [ "$REPLY" != "y" -a "$REPLY" != "Y" ] && return 3
    # Rebuild master branch
    git branch -m old-master
    git checkout --orphan master
    git add .
    git commit -m 'first commit'
    # Rebuild git-annex branch
    git branch -m git-annex old-git-annex
    git checkout old-git-annex
    git checkout --orphan git-annex
    git add .
    git commit -m 'first commit'
    git checkout master
    # Cleanup
    git branch -D old-master old-git-annex
    git reflog expire --expire=now --all
    git prune
    git gc
  )
}

# Delete all versions of a file
# https://git-annex.branchable.com/tips/deleting_unwanted_files/
annex_purge() {
  annex_exists || return 1
  local IFS="$(printf ' \t\n')"
  for F; do
    echo "Delete file '$F' ? (y/n)"
    read REPLY </dev/tty
    [ "$REPLY" = "y" -o "$REPLY" = "Y" ] || continue
    git annex whereis "$F"
    git annex drop --force "$F"
    for R in $(annex_enabled); do
      git annex drop --force "$F" --from "$R"
    done
    rm "$F" 2>/dev/null
  done
  git annex sync
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#annex}" != "$1" ] && "$@" || true
