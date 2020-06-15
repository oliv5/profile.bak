#!/bin/sh

# Get annex version
annex_version() {
  if [ $# -gt 0 ]; then
    echo "$@" | awk -F'.' '{printf "%.d%.8d\n",$1,$2$3$4}'
  else
    git annex version | awk -F'[ .]' '/git-annex version:/ {printf "%.d%.8d\n",$3,$4}'
  fi
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
  annex_exists "$@" && ! annex_direct "$@" && git_bare "$@"
}

# Test annex standard (indirect, not bare)
annex_std() {
  annex_exists "$@" && ! annex_direct "$@" && ! git_bare "$@"
}

# Get root dir
annex_root() {
  annex_direct "$@" && readlink -f "$(git_root "$@")/.." || git_root "$@"
}

########################################
# Init annex
annex_init() {
  git init "${1:-.}" && git --git-dir="${1:-.}/.git" annex init "${2:-$(uname -n)}"
}

# Init annex bare repo
annex_init_bare() {
  git init --bare "${1:-.}" && git --git-dir="${1:-.}" annex init "${2:-$(uname -n)}"
}

# Uninit annex
annex_uninit() {
  git --git-dir="${1:-.}" annex uninit && 
  git --git-dir="${1:-.}" config --replace-all core.bare false
}

# Init annex in direct mode
annex_init_direct() {
  annex_init "$@" && git --git-dir="${1:-.}" annex direct
}

# Setup v7 annex in dual mode: plain & annexed files
# https://git-annex.branchable.com/git-annex/
# https://git-annex.branchable.com/tips/largefiles/
# https://git-annex.branchable.com/forum/Annex_v7_repos_and_plain_git_files/
# https://git-annex.branchable.com/forum/lets_discuss_git_add_behavior/#comment-37e0ecaf8e0f763229fd7b8ee9b5a577
annex_mixed_content() {
  local SIZE="${1:-nothing}"
  local LOCAL="${2:-1}"
  if [ -n "$LOCAL" ]; then
    _set_config() { git config --replace-all "$@"; }
    _rm_config() { git config --unset-all "$1"; }
  else
    _set_config() { git annex config --set "$@"; }
    _rm_config() { git annex config --unset "$1"; }
  fi
  if [ "$SIZE" = "remove" ] || [ "$SIZE" = "rm" ]; then
    _rm_config annex.gitaddtoannex
    _rm_config annex.addsmallfiles
    _rm_config annex.largefiles
  elif [ "$SIZE" = "anything" ] || [ "$SIZE" = "all" ]; then
    _set_config annex.gitaddtoannex "true"
    _set_config annex.addsmallfiles "true"
    _set_config annex.largefiles "anything"
  elif [ "$SIZE" = "nothing" ] || [ "$SIZE" = "none" ]; then
    _set_config annex.gitaddtoannex "false"
    _set_config annex.addsmallfiles "false"
    #_set_config annex.largefiles "nothing"
    _rm_config annex.largefiles
  else
    _set_config annex.gitaddtoannex "false"
    _set_config annex.addsmallfiles "false"
    _set_config annex.largefiles "$SIZE"
  fi
}

########################################
# Init hubic annex
annex_init_hubic() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=hubic hubic_container=annex hubic_path="$REMOTEPATH" embedcreds=no ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=external externaltype=hubic hubic_container=annex hubic_path="$REMOTEPATH" embedcreds=no ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"}
}

# Init gdrive annex
annex_init_gdrive() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=googledrive folder="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=external externaltype=googledrive folder="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"}
}

# Init bup annex
annex_init_bup() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=bup buprepo="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=bup buprepo="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"}
}

# Init rsync annex
annex_init_rsync() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=rsync rsyncurl="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=rsync rsyncurl="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"}
  git config --add annex.sshcaching false
}

# Init directory annex
annex_init_directory() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  local EXPORTTREE="$6"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=directory directory="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ${EXPORTTREE:+exporttree=yes} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=directory directory="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ${EXPORTTREE:+exporttree=yes}
  git config --add annex.sshcaching false
}

# Init gcrypt annex
annex_init_gcrypt() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=gcrypt gitrepo="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"} ||
  git annex initremote   "$NAME" encryption="$ENCRYPTION" type=gcrypt gitrepo="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} ${KEYID:+keyid="$KEYID"}
  git config --add annex.sshcaching false
}

# Clone gcrypt annex
annex_clone_gcrypt() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  ! git-remote-gcrypt --check "$REMOTEPATH" && return 1
  git clone "gcrypt::$REMOTEPATH" "$NAME" &&
    git annex enableremote "$NAME" type=gcrypt gitrepo="$REMOTEPATH"
}

# Init rclone annex
annex_init_rclone() {
  local NAME="${1:?No remote name specified...}"
  local REMOTEPATH="${2:-$(git_repo)}"
  local ENCRYPTION="${3:-none}"
  local KEYID="$4"
  local CHUNKS="$5"
  local PROFILE="${6:-$NAME}"
  local MAC="${7:-HMACSHA512}"
  local LAYOUT="${8:-lower}"
  git annex enableremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=rclone target="$PROFILE" prefix="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} mac="${MAC}" rclone_layout="$LAYOUT" ${KEYID:+keyid="$KEYID"} ||
  git annex initremote "$NAME" encryption="$ENCRYPTION" type=external externaltype=rclone target="$PROFILE" prefix="$REMOTEPATH" ${CHUNKS:+chunk=$CHUNKS} mac="${MAC}" rclone_layout="$LAYOUT" ${KEYID:+keyid="$KEYID"}
}

########################################
# Git status for scripts
annex_st() {
  git annex status | awk -F'#;#.' '/^[\? ]?'$1'[\? ]?/ {sub(/ /,"#;#.");print $2}'
}

########################################
# List remotes uuids
annex_uuid() {
  for REMOTE in "${@:-.*}"; do
    git config --get-regexp remote\.${REMOTE}\.annex-uuid
  done | cut -d' ' -f 2 | xargs
}
annex_uuid_all() {
  for REMOTE in "${@:-.*}"; do
    git show git-annex:uuid.log | awk '$2=/'$REMOTE'/ {print $1}'
  done | xargs
}
annex_uuid_local() {
  git config annex.uuid
}

####
# List remotes
annex_remotes() {
  for REMOTE in "${@:-.*}"; do
    git config --get-regexp "remote\..*${REMOTE}.*\.annex-uuid"
  done | awk -F. '{print $2}' | sort -u | xargs
}
annex_remotes_all() {
  for REMOTE in "${@:-.*}"; do
    git show git-annex:uuid.log |
      awk "\$2 ~ /${REMOTE}/ {print \$2}"
  done | xargs
}
annex_remotes_by_uuid() {
  for UUID; do
    git show git-annex:uuid.log |
    awk "\$1 ~ /$UUID/ {print \$2}"
  done | xargs
}

####
# List enabled local remotes
annex_enabled() {
  local EXCLUDE="$(git config --get-regexp "remote\..*\.annex-ignore" true | awk -F. '{printf $2"|"}' | sed -e "s/|$//")"
  git config --get-regexp "remote\..*\.annex-uuid" |
    grep -vE "${EXCLUDE:-$^}" | 
    awk -F. '{print $2}' |
    sort -u |
    xargs
}

####
# Check if remote is dead
annex_isdead_by_uuid() {
  local STATUS
  for UUID; do
    STATUS="$(git show git-annex:trust.log | awk "\$1 ~ /$UUID/ {print \$2}")"
    [ "$STATUS" = "X" ] || return 1
  done
}
annex_isdead() {
  annex_isdead_by_uuid $(annex_uuid_all "$@")
}

####
# Get dead remotes names/uuids
annex_dead_uuid() {
  for REMOTE in $(annex_uuid_all "$@"); do
    annex_isdead_by_uuid "$REMOTE" && echo "$REMOTE"
  done | xargs
}
annex_dead() {
  for REMOTE in $(annex_remotes_all "$@"); do
    annex_isdead "$REMOTE" && echo "$REMOTE"
  done | xargs
}
annex_notdead_uuid() {
  for REMOTE in $(annex_uuid_all "$@"); do
    ! annex_isdead_by_uuid "$REMOTE" && echo "$REMOTE"
  done | xargs
}
annex_notdead() {
  for REMOTE in $(annex_remotes_all "$@"); do
    ! annex_isdead "$REMOTE" && echo "$REMOTE"
  done | xargs
}

####
# List special remotes
annex_special_remotes() {
  git show git-annex:remote.log 2>/dev/null |
    perl -n -e'/^'$1'.*name=(\w+)/ && print "$1\n"' |
    sort -u |
    xargs
}
annex_special_remotes_uuid() {
  git show git-annex:remote.log 2>/dev/null |
    awk '/'$1'/{print $1}' |
    sort -u |
    xargs
}
annex_isspecial() {
  git show git-annex:remote.log 2>/dev/null | grep "name=$1" >/dev/null
}
annex_special_remotes_dead() {
  annex_dead $(annex_special_remotes "$@")
}
annex_special_remotes_not_dead() {
  annex_notdead $(annex_special_remotes "$@")
}

########################################
annex_hook_commit() {
  local HOOK="$(git_dir)/hooks/pre-commit"
  [ -e "$HOOK" ] && { echo "Hook file $HOOK exists already..."; return 1; }
  cat > "$HOOK" <<EOF
#!/bin/sh
# automatically configured by git-annex
git annex pre-commit .

# Go though added files (--diff-filter=A) and check whether they are symlinks (test -h)
git diff --cached --name-only --diff-filter=A -z |
    xargs -r -0 -- sh -c '
        for F; do
            test ! -h "\$F" && echo "File \"\$F\" is not a symlink. Abort..." && exit 1
        done
    ' _
EOF
  chmod +x "$HOOK"
}

########################################
# Print annex infos (inc. encryption ciphers)
annex_getinfo() {
  git annex info .
  git show git-annex:remote.log
  for REMOTE in ${@:-$(annex_remotes)}; do
    echo '-------------------------'
    git annex info "$REMOTE"
  done
}

# Lookup special remote keys
annex_lookup_special_remote() {
  # Preamble
  git_exists || return 1
  annex_std || return 2
  annex_isspecial || return 3
  # Bash lookup_key
  bash_lookup_key() {
    bash -c '
      # Decrypt cipher
      decrypt_cipher() {
        cipher="$1"
        echo "$(echo -n "$cipher" | base64 -d | gpg --decrypt --quiet)"
      }
      # Encrypt git-annex key
      encrypt_key() {
        local key="$1"
        local cipher="$2"
        local mac="$3"
        local enckey="$key"
        if [ -n "$cipher" ]; then
          enckey="GPG$mac--$(echo -n "$key" | openssl dgst -${mac#HMAC} -hmac "$cipher" | sed "s/(stdin)= //")"
        fi
        local checksum="$(echo -n $enckey | md5sum)"
        echo "${checksum:0:3}/${checksum:3:3}/$enckey"
      }
      # Find the special remote key from the local key
      lookup_key() {
        local encryption="$1"
        local cipher="$2"
        local mac="$3"
        local remote_uuid="$4"
        local file="$(readlink -m "$5")"
        # No file
        if [ -z "$file" ]; then
          echo >&2 "File \"$5\" does not exist..."
          exit 1
        fi
        # Analyse keys
        local annex_key="$(basename "$file")"
        local checksum="$(echo -n "$annex_key" | md5sum)"
        local branchdir="${checksum:0:3}/${checksum:3:3}"
        if [ "$(git config annex.tune.branchhash1)" = "true" ]; then
            branchdir="${branchdir%%/*}"
        fi
        local chunklog="$(git show "git-annex:$branchdir/$annex_key.log.cnk" 2>/dev/null | grep $remote_uuid: | grep -v " 0$")"
        local chunklog_lc="$(echo "$chunklog" | wc -l)"
        local chunksize numchunks chunk_key line n
        # Decrypt cipher
        if [ "$encryption" = "hybrid" ] || [ "$encryption" = "pubkey" ]; then
            cipher="$(decrypt_cipher "$cipher")"
        fi
        # Pull out MAC cipher from beginning of cipher
        if [ "$encryption" = "hybrid" ] ; then
            cipher="$(echo -n "$cipher" | head  -c 256 )"
        elif [ "$encryption" = "shared" ] ; then
            cipher="$(echo -n "$cipher" | base64 -d | tr -d "\n" | head  -c 256 )"
        elif [ "$encryption" = "pubkey" ] ; then
            # pubkey cipher includes a trailing newline which was stripped in
            # decrypt_cipher process substitution step above
            #IFS= read -rd '' cipher < <( printf "$cipher\n" )
            cipher="$cipher
"
        elif [ "$encryption" = "sharedpubkey" ] ; then
            # Full cipher is base64 decoded. Add a trailing \n lost by the shell somewhere
            cipher="$(echo -n "$cipher" | base64 -d)
"
        fi
        if [ -z "$chunklog" ]; then
            echo "# non-chunked" >&2
            encrypt_key "$annex_key" "$cipher" "$mac"
        elif [ "$chunklog_lc" -ge 1 ]; then
            if [ "$chunklog_lc" -ge 2 ]; then
                echo "INFO: the remote seems to have multiple sets of chunks" >&2
            fi
            echo "$chunklog" | while read -r line; do
                chunksize="$(echo -n "${line#*:}" | cut -d " " -f 1)"
                numchunks="$(echo -n "${line#*:}" | cut -d " " -f 2)"
                echo "# $numchunks chunks of $chunksize bytes" >&2
                for n in $(seq 1 $numchunks); do
                    chunk_key="${annex_key/--/-S$chunksize-C$n--}"
                    encrypt_key "$chunk_key" "$cipher" "$mac"
                done
            done
        fi
      }
      # Main call
      lookup_key "$@"
    ' _ "$@"
  }
  # Main variables
  local REMOTE="${1:?No remote specified...}"
  local REMOTE_CONFIG="$(git show git-annex:remote.log | grep 'name='"$REMOTE " | head -n 1)"
  local ENCRYPTION="$(echo "$REMOTE_CONFIG" | grep -oP 'encryption\=.*? ' | tr -d ' \n' | sed 's/encryption=//')"
  local CIPHER="$(echo "$REMOTE_CONFIG" | grep -oP 'cipher\=.*? ' | tr -d ' \n' | sed 's/cipher=//')"
  local UUID="$(echo "$REMOTE_CONFIG" | cut -d ' ' -f 1)"
  local MAC="$(echo "$REMOTE_CONFIG" | grep -oP 'mac\=.*? ' | tr -d ' \n' | sed 's/mac=//')"
  [ -z "$REMOTE_CONFIG" ] && { echo >&2 "Remote '$REMOTE' config not found..."; return 3; }
  [ -z "$ENCRYPTION" ] && { echo >&2 "Remote '$REMOTE' encryption not found..."; return 3; }
  [ -z "$CIPHER" -a "$ENCRYPTION" != "none" ] && { echo >&2 "Remote '$REMOTE' cipher not found..."; return 3; }
  [ -z "$UUID" ] && { echo >&2 "Remote '$REMOTE' uuid not found..."; return 3; }
  [ -z "$MAC" ] && MAC=HMACSHA1
  shift 1
  # Main processing
  echo "## Remote $REMOTE"
  echo "## Uuid $UUID"
  echo "## Encryption $ENCRYPTION"
  echo "## Cipher $CIPHER"
  echo "## Mac $MAC"
  echo
  git annex find --include '*' "$@" --format='${hashdirmixed}${key}/${key} ${hashdirlower}${key}/${key} ${file}\n' | while IFS=' ' read -r KEY1 KEY2 FILE; do
    echo "$REMOTE"
    echo "$FILE"
    echo "$KEY1"
    echo "$KEY2"
    bash_lookup_key "$ENCRYPTION" "$CIPHER" "$MAC" "$UUID" "$FILE"
    echo
  done
}

# Lookup special remotes keys
annex_lookup_special_remotes() {
  local REMOTES="${@:-$(annex_special_remotes_notdead)}"
  for REMOTE in $REMOTES; do
    annex_lookup_special_remote "$REMOTE" 2>&1
  done
}

########################################
# List annex content in an archive
_annex_archive() {
  ( set +e; # Need to go on on error
    annex_exists || return 1
    local OUT="${1:?No output file name specified...}"
    local DIR="${2:-$(git_dir)/bundle}"
    local NAME="$(git_repo).$(uname -n).$(date +%Y%m%d-%H%M%S).$(git_shorthash)"
    OUT="$DIR/${NAME}.${OUT%%.*}.${OUT#*.}"
    local GPG_RECIPIENT="$3"
    local GPG_TRUST="${4:+--trust-model always}"
    shift 4
    mkdir -p "$(dirname "$OUT")"
    if [ $? -ne 0 ]; then
      echo "Cannot create directory '$(dirname "$OUT")'. Abort..."
      return 1
    fi
    echo "Generate $OUT"
    eval "$@"
    if [ ! -r "${OUT}" ]; then
      echo "Output file '${OUT}' is missing or empty. Abort..."
      return 1
    fi
    if [ ! -z "$GPG_RECIPIENT" ]; then
      gpg -v --output "${OUT}.gpg" --encrypt --recipient "$GPG_RECIPIENT" $GPG_TRUST "${OUT}" &&
        _git_secure_delete "${OUT}"
    fi
    ls -l "${OUT}"*
  )
}

# Annex bundle
_annex_bundle() {
  [ -n "$OUT" ] || return 1
  OUT="${OUT%%.xz}"; OUT="${OUT%%.tar}.tar.xz"
  local OWNER="${1:-$USER}"
  local XZOPTS="${2:--9}"
  if annex_bare; then
    if [ -d "$(git_dir)/annex" ]; then
      echo "Skip empty bundle..."
      return 1
    fi
    tar c -h -O --exclude='*/creds/*' -- "$(git_dir)/annex" |
      xz -z -c --verbose ${XZOPTS} - > "${OUT}"
  else
    if [ $(git annex find 2>/dev/null | wc -l) -eq 0 ]; then
      echo "Skip empty bundle..."
      return 1
    fi
    git annex find --print0 | 
      xargs -r0 tar c -h -O --exclude-vcs -- |
        xz -z -c --verbose ${XZOPTS} - > "${OUT}"
  fi
  [ -f "$OUT" ] && chown "$OWNER" "$OUT"
}
annex_bundle() {
  _annex_archive "annex.bundle.tar.xz" "$1" "$2" "$3" "_annex_bundle" "$4" "$5"
}

# Annex enumeration
_annex_enum() {
  [ -n "$OUT" ] || return 1
  OUT="${OUT%%.xz}"; OUT="${OUT%%.txt}.txt.xz"
  local OWNER="${1:-$USER}"
  local XZOPTS="${2:--9}"
  if annex_bare; then
    echo "Repository '$(git_dir)' cannot be enumerated. Abort..."
    return 2
  else
    git annex find --include '*' --print0 | xargs -r0 -n1 sh -c '
      FILE="$1"
      #printf "\"%s\" \"%s\"\n" "$(readlink -- "$FILE")" "$FILE" | grep -F ".git/annex"
      readlink -- "$FILE" | base64 -w 0
      echo
      echo "$FILE" | base64 -w 0
      echo
    ' _ > "${OUT%%.txt.xz}.txt"
    xz -k -z -S .xz --verbose ${XZOPTS} "${OUT%%.txt.xz}.txt" &&
      _git_secure_delete "${OUT%%.txt.xz}.txt"
  fi
  [ -f "$OUT" ] && chown "$OWNER" "$OUT"
}
annex_enum() {
  _annex_archive "annex.enum_local.txt.xz" "$1" "$2" "$3" "_annex_enum" "$4" "$5"
}

# Store annex infos
_annex_info() {
  [ -n "$OUT" ] || return 1
  OUT="${OUT%%.xz}"; OUT="${OUT%%.txt}.txt.xz"
  local OWNER="${1:-$USER}"
  local XZOPTS="${2:--9}"
  annex_getinfo > "${OUT%%.xz}"
  xz -k -z -S .xz --verbose ${XZOPTS} "${OUT%%.xz}" &&
    _git_secure_delete "${OUT%%.xz}"
  [ -f "$OUT" ] && chown "$OWNER" "$OUT"
}
annex_info(){
  _annex_archive "annex.info.txt.xz" "$1" "$2" "$3" "_annex_info" "$4" "$5"
}

# Enum special remotes
_annex_enum_special_remotes() {
  [ -n "$OUT" ] || return 1
  OUT="${OUT%%.xz}"; OUT="${OUT%%.txt}.txt.xz"
  local OWNER="${1:-$USER}"
  local XZOPTS="${2:--9}"
  annex_lookup_special_remotes > "${OUT%%.xz}"
  xz -k -z -S .xz --verbose ${XZOPTS} "${OUT%%.xz}" &&
    _git_secure_delete "${OUT%%.xz}"
  [ -f "$OUT" ] && chown "$OWNER" "$OUT"
}
annex_enum_special_remotes() {
  if annex_bare; then
    echo "Repository '$(git_dir)' cannot be enumerated. Abort..."
    return 1
  else
    _annex_archive "annex.enum_special_remotes.txt.xz" "$1" "$2" "$3" "_annex_enum_special_remotes" "$4" "$5"
  fi
}

########################################
# Annex upload
annex_upload() {
  local ARGS=""
  local PREV=""
  local TO=""
  for ARG; do
     if [ "$PREV" = "--to" ]; then
      TO="${TO:+$TO }'$ARG'"
     elif [ "$ARG" != "--to" ]; then
      ARGS="${ARGS:+$ARGS }'$ARG'"
     fi
     PREV="$ARG"
  done
  for REMOTE in ${TO:-$(annex_enabled)}; do
    eval git annex copy ${ARGS:-.} --to "$REMOTE"
  done
}

########################################
# Transfer files to the specified repos by chunk of a given size
# without downloading the whole repo locally at once
# $FROM is used to selected the origin repo
# $DBG is used to print the command on stderr (when not empty)
# $ALL is used to select all files (when not empty)
alias annex_transfer='DBG= FROM= ALL= _annex_transfer'
_annex_transfer() {
  annex_exists || return 1
  local REPOS="${1:-$(annex_enabled)}"
  local MAXSIZE="${2:-1073741824}"
  local DBG="${DBG:+echo}"
  local SELECT=""
  [ $# -le 2 ] && shift $# || shift 2
  [ -z "$REPOS" ] && return 0
  [ -z "$ALL" ] && for REPO in $REPOS; do SELECT="${SELECT:+ $SELECT --and }--not --in $REPO"; done
  if git_bare; then
    # Bare repositories do not have "git annex find"
    echo "BARE REPOS NOT SUPPORTED YET"
  else
    # Plain git repositories
    git annex sync
    # 1) copy the local files
    for REPO in $REPOS; do
      while ! $DBG git annex copy --to "$REPO" --fast "$@"; do sleep 1; done
    done
    # 2) get, copy and drop the remote files
    git annex find --include='*' $SELECT --print0 "$@" | xargs -0 -r sh -c '
      DBG="$1";REPOS="$2";MAXSIZE="$3";FROM="$4"
      shift 4
      TOTALSIZE=0
      NUMFILES=$#
      for FILE; do
        # Init
        NUMFILES=$(($NUMFILES - 1))
        [ $TOTALSIZE -eq 0 ] && set --
        # Get current file size
        SIZE=$(git annex info --bytes "$FILE" | awk "/size:/{print \$2}")
        # List the current file
        if [ $SIZE -le $MAXSIZE ]; then
          set -- "$@" "$FILE"
          TOTALSIZE=$(($TOTALSIZE + $SIZE))
        else
          echo "File \"$FILE\" size ($SIZE) is greater than max size ($MAXSIZE). Skip it..."
        fi
        # Check if the transfer limits or last file were reached
        if [ $TOTALSIZE -ge $MAXSIZE -o $NUMFILES -eq 0 ]; then
          # Transfer the listed files so far, if any
          if [ $# -gt 0 ]; then
            while ! $DBG git annex get ${FROM:+--from "$FROM"} "$@"; do sleep 1; done
            for REPO in $REPOS; do
              while ! $DBG git annex copy --to "$REPO" "$@"; do sleep 1; done
            done
            $DBG git annex drop "$@"
          fi
          # Empty list
          set --
          TOTALSIZE=0
        fi
      done
      exit 0
    ' _ "$DBG" "$REPOS" "$MAXSIZE" "$FROM"
  fi
}

# Rsync files to the specified location by chunk of a given size
# without downloading the whole repo locally at once
# Options make it similar to "git annex copy" and "git annex move"
# $FROM is used to selected the origin repo
# $DBG is used to print the command on stderr (when not empty)
# $SKIP_EXISTING is used to skip existing remote files
# $DELETE is used to delete the missing existing files (1=dry-run, 2=do-it)
# $RSYNC_OPT is used to specify rsync options
alias annex_rsync='DBG= DELETE= SKIP_EXISTING= RSYNC_OPT= _annex_rsync'
alias annex_rsyncd='DBG= DELETE=2 SKIP_EXISTING= RSYNC_OPT= _annex_rsync'
alias annex_rsyncds='DBG= DELETE=1 SKIP_EXISTING= RSYNC_OPT= _annex_rsync'
_annex_rsync() {
  annex_exists || return 1
  local DST="${1:?No destination specified...}"
  local MAXSIZE="${2:-1073741824}"
  local SRC="${PWD}"
  local DBG="${DBG:+echo [DBG]}"
  local RSYNC_OPT="${RSYNC_OPT:--v -r -z -s -i --inplace --size-only --progress -K -L -P}"
  [ $# -le 2 ] && shift $# || shift 2
  [ "${SRC%/}" = "${DST%/}" ] && return 2
  [ "${DST%%:*}" = "${DST}" ] && DST="localhost:/${DST}"
  if git_bare; then
    # Bare repositories do not have "git annex find"
    echo "BARE REPOS NOT TESTED YET. Press enter to go on..." && read NOP
    git annex sync
    find annex/objects -type f | while read SRCNAME; do
      annex_fromkey0 "$SRCNAME" | xargs -0 -rn1 echo | while read DSTNAME; do
        DST_DIR="$(dirname "${DST##*:}/${DSTNAME}")"
        while ! $DBG rsync -K -L --rsync-path="mkdir -p \"${DST_DIR}\" && rsync" $RSYNC_OPT "${SRC}/${SRCNAME}" "${DST}/${DSTNAME}"; do sleep 1; done
      done
    done
  else
    # Plain git repositories
    git annex sync
    # 1) copy the local files
    for FILE; do
      DST_DIR="$(dirname "${DST##*:}/${FILE}")"
      while ! $DBG rsync -K -L --rsync-path="mkdir -p \"$DST_DIR\" && rsync" $RSYNC_OPT "$FILE" "$DST/$FILE"; do sleep 1; done
    done
    # 2) get, copy and drop the remote files
    git annex find --include='*' --print0 "$@" | xargs -0 -r sh -c '
      DBG="$1";MAXSIZE="$2";SKIP_EXISTING="$3";RSYNC_OPT="$4";DST="$5"
      shift 5
      TOTALSIZE=0
      NUMFILES=$#
      DST_PROTO="${DST%%/*}"
      DST_SERVER="${DST_PROTO%%:*}"
      DST_PORT="${DST_PROTO##${DST_SERVER}:}"
      DST_ROOT="/${DST#*/}"
      for FILE; do
        # Init
        NUMFILES=$(($NUMFILES - 1))
        [ $TOTALSIZE -eq 0 ] && set --
        # Get current file size
        SIZE=$(git annex info --bytes "$FILE" | awk "/size:/{print \$2}")
        # List the current file
        if [ $SIZE -gt $MAXSIZE ]; then
          echo "File \"$FILE\" size ($SIZE) is greater than max size ($MAXSIZE). Skip it..."
        elif [ -n "$SKIP_EXISTING" ]; then
          # Skip existing files
          DST_SIZE=0
          DST_FILE="${DST_ROOT}/$FILE"
          [ "$DST_SERVER" != "localhost" ] && 
            DST_SIZE=$(ssh ${DST_PORT:+-p "$DST_PORT"} "$DST_SERVER" stat -c %s "$DST_FILE" 2>&1) ||
            DST_SIZE=$(stat -c %s "$DST_FILE" 2>&1)
          if [ "$DST_SIZE" = "$SIZE" ]; then
            echo "Skip identical existing file ${DST_FILE}"
          else
            # Enqueue the file
            set -- "$@" "$FILE"
            TOTALSIZE=$(($TOTALSIZE + $SIZE))
          fi
        else
          # Enqueue the file
          set -- "$@" "$FILE"
          TOTALSIZE=$(($TOTALSIZE + $SIZE))
        fi
        # Check if the transfer limits or last file were reached
        if [ $TOTALSIZE -ge $MAXSIZE -o $NUMFILES -eq 0 ]; then
          # Transfer the listed files so far, if any
          if [ $# -gt 0 ]; then
            while ! $DBG git annex get ${FROM:+--from "$FROM"} "$@"; do sleep 1; done
            for FILE; do
              DST_DIR="$(dirname "${DST##*:}/${FILE}")"
              while ! $DBG rsync -K -L --rsync-path="mkdir -p \"$DST_DIR\" && rsync" $RSYNC_OPT "$FILE" "$DST/$FILE"; do sleep 1; done
            done
            while ! $DBG git annex drop "$@"; do sleep 1; done
          fi
          # Empty list
          set --
          TOTALSIZE=0
        fi
      done
      exit 0
    ' _ "$DBG" "$MAXSIZE" "${SKIP_EXISTING:+1}" "$RSYNC_OPT" "$DST"
    # Delete missing destination files
    if [ "$DELETE" = 1 ]; then
      while ! $DBG rsync --dry-run -ri --delete --cvs-exclude --ignore-existing --ignore-non-existing "$SRC/" "$DST/"; do sleep 1; done
    elif [ "$DELETE" = 2 ]; then
      while ! $DBG rsync -ri --delete --cvs-exclude --ignore-existing --ignore-non-existing "$SRC/" "$DST/"; do sleep 1; done
    fi
  fi
}

########################################
# Populate a special remote directory with files from the input source
# The current repository is used to find out keys & file names,
# but is not used directly to copy/move the files from
# Note the same backend than the source is used for the destination file names
# WHERE selects which files & repo to look for
# MOVE=1 moves files instead of copying them
alias annex_populate='MOVE= _annex_populate'
alias annex_populatem='MOVE=1 _annex_populate'
_annex_populate() {
  local DST="${1:?No dst directory specified...}"
  local SRC="${2:-$PWD}"
  local WHERE="${3:-${WHERE:---include '*'}}"
  git annex sync
  eval git annex find "$WHERE" --format='\${file}\\000\${hashdirlower}\${key}/\${key}\\000' | xargs -r0 -n2 sh -c '
    DBG="$1"; MOVE="$2"; SRCDIR="$3; DSTDIR="$4"; SRC="$SRCDIR/$5"; DST="$DSTDIR/$6"
    echo "$SRC -> $DST"
    if [ -d "$SRCDIR" -o -d "$DSTDIR" ]; then
      if [ -n "$MOVE" ]; then
        if [ -r "$SRC" -a ! -h "$SRC" ]; then
          $DBG mkdir -p "$(dirname "$DST")"
          $DBG mv -f -T "$SRC" "$DST"
        else
          $DBG rsync -K -L --protect-args --remove-source-files "$SRC" "$DST"
        fi
      else
        $DBG rsync -K -L --protect-args "$SRC" "$DST"
      fi
    fi
  ' _ "${DBG:+echo [DBG]}" "$MOVE" "$SRC" "$DST"
}

########################################
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

########################################
# Annex upkeep
annex_upkeep() {
  devcat() {
    { if command -v sudo >/dev/null; then sudo cat "$1"; else su -c "cat '$1'" root; stty sane 2>/dev/null; fi; } | tr '[:upper:]' '[:lower:]' | xargs printf '%s'
  }
  local DBG=""
  local IFS="$(printf ' \t\n')"
  # Add options
  local ADD=""
  local DEL=""
  local FORCE=""
  # Sync options
  local MSG="annex_upkeep() at $(date)"
  local SYNC=""
  local NO_COMMIT="--no-commit"
  local NO_PULL="--no-pull"
  local NO_PUSH="--no-push"
  local CONTENT=""
  # Copy options
  local GET=""
  local SEND=""
  local FAST="--all"
  local REMOTES=""
  # Misc options
  local NETWORK_DEVICE="";
  local CHARGE_LEVEL="";
  local CHARGE_STATUS="";
  # Get arguments
  OPTIND=1
  while getopts "adoscpum:gefti:v:w:zh" OPTFLAG; do
    case "$OPTFLAG" in
      # Add
      a) ADD=1;;
      d) DEL=1;;
      o) FORCE=1;;
      # Sync
      s) SYNC=1; NO_COMMIT=""; NO_PULL=""; NO_PUSH="";;
      c) SYNC=1; NO_COMMIT="";;
      p) SYNC=1; NO_PULL="";;
      u) SYNC=1; NO_PUSH="";;
      t) SYNC=1; CONTENT="--content";;
      m) MSG="${OPTARG}";;
      # UL/DL
      g) GET=1;;
      e) SEND=1;;
      r) REMOTES="${OPTARG}";;
      f) FAST="--fast";;
      # Misc
      i) NETWORK_DEVICE="${OPTARG}";;
      v) CHARGE_LEVEL="${OPTARG}";;
      w) CHARGE_STATUS="${OPTARG}";;
      z) set -vx; DBG="true";;
      *) echo >&2 "Usage: annex_upkeep [-a] [-d] [-o] [-s] [-t] [-c] [-p] [-u] [-m 'msg'] [-g] [-e] [-f] [-i itf] [-v 'var lvl'] [-w 'var status1 status2 ...'] [-z] [remote1 remote2 ...] "
         echo >&2 "-a (a)dd new files"
         echo >&2 "-d add (d)eleted files"
         echo >&2 "-o f(o)rce add/delete files"
         echo >&2 "-s (s)ync, similar to -cpu"
         echo >&2 "-t sync conten(t)"
         echo >&2 "-c (c)ommit"
         echo >&2 "-p (p)ull"
         echo >&2 "-u p(u)sh"
         echo >&2 "-m (m)essage"
         echo >&2 "-g (g)et"
         echo >&2 "-e s(e)nd to remotes"
         echo >&2 "-f (f)ast get/send"
         echo >&2 "-i check network (i)nterface connection"
         echo >&2 "-v check device charging le(v)el"
         echo >&2 "-w check device charging status"
         echo >&2 "-z simulate operations"
         return 1;;
    esac
  done
  shift "$((OPTIND-1))"
  unset OPTFLAG OPTARG
  OPTIND=1
  REMOTES="${@:-$(annex_enabled)}"
  # Base check
  annex_exists || return 1
  # Charging status
  if [ -n "$CHARGE_STATUS" ]; then
    set -- $CHARGE_STATUS
    local DEVICE="${1:-/sys/class/power_supply/battery/status}"
    shift
    local CURRENT_STATUS="$(devcat "$DEVICE")"
    local EXPECTED_STATUS="$*"
    local REMAINING_STATUS="${EXPECTED_STATUS%${CURRENT_STATUS}*}"
    set --
    if [ "$REMAINING_STATUS" = "$EXPECTED_STATUS" ]; then
      echo "[warning] device is not in charge ($CURRENT_STATUS / $EXPECTED_STATUS). Abort..."
      return 3
    fi
  fi
  # Charging level
  if [ -n "$CHARGE_LEVEL" ]; then
    set -- $CHARGE_LEVEL
    local DEVICE="${1:-/sys/class/power_supply/battery/capacity}"
    local CURRENT_LEVEL="$(devcat "$DEVICE")"
    local EXPECTED_LEVEL="${2:-75}"
    set --
    if [ "$CURRENT_LEVEL" -lt "$EXPECTED_LEVEL" 2>/dev/null ]; then
      echo "[warning] device charge level ($CURRENT_LEVEL) is lower than threshold ($EXPECTED_LEVEL). Abort..."
      return 2
    fi
  fi
  # Connected network device
  #if [ -n "$NETWORK_DEVICE" ] && ! ip addr show dev "$NETWORK_DEVICE" 2>/dev/null | grep "state UP" >/dev/null; then
  if [ -n "$NETWORK_DEVICE" ] && ! ip addr show dev "$NETWORK_DEVICE" 2>/dev/null | head -n 1 | grep "UP" >/dev/null; then
    echo "[warning] network interface '$NETWORK_DEVICE' is not connected. Disable file content transfer..."
    unset CONTENT
    unset GET
    unset SEND
  fi
  # Force PULL if a remote is using gcrypt
  if [ -n "$NO_PULL" ] && git_gcrypt_remotes $REMOTES; then
    echo "Force pull because of gcrypt remote(s)"
    unset NO_PULL
  fi
  # Add
  if [ -n "$ADD" ]; then
    $DBG git annex add . ${FORCE:+--force} || return $?
  fi
  # Revert deleted files
  if [ -z "$DEL" ] && ! annex_direct; then
    gstx D | xargs -r0 $DBG git checkout || return $?
    #annex_st D | xargs -r $DBG git checkout || return $?
  fi
  # Sync
  if [ -n "$SYNC" ]; then
    $DBG git annex sync ${NO_COMMIT} ${NO_PULL} ${NO_PUSH} ${CONTENT} ${MSG:+--message="$MSG"} $REMOTES || return $?
  fi
  # Get
  if [ -n "$GET" ]; then
      $DBG git annex get ${FAST} || return $?
  fi
  # Upload
  if [ -n "$SEND" ]; then
    for REMOTE in ${REMOTES}; do
      $DBG git annex copy --to "$REMOTE" ${FAST} || return $?
    done
  fi
  return 0
}

########################################
# Find aliases
alias annex_existing='git annex find --in'
alias annex_existing0='git annex find --print0 --in'
alias annex_missing='git annex find --not --in'
alias annex_missing0='git annex find --print0 --not --in'
alias annex_wantget='git annex find --want-get --not --in'
alias annex_wantget0='git annex find --print0 --want-get --not --in'
alias annex_wantdrop='git annex find --want-drop --in'
alias annex_wantdrop0='git annex find --print0 --want-drop --in'
annex_existingc() { annex_existing "$@" | wc -l; }
annex_missingc()  { annex_missing "$REMOTE" | wc -l; }
annex_wantgetc()  { annex_wantget "$REMOTE" | wc -l; }
annex_wantdropc() { annex_wantdrop "$REMOTE" | wc -l; }
annex_lost()  { git annex list "$@" | grep -E "^_+ "; }
annex_lostc() { git annex list "$@" | grep -E "^_+ " | wc -l; }

# Grouped find aliases
annex_existingn() { for REMOTE in ${@:-$(annex_remotes) .}; do echo "*** Existing in $REMOTE ***"; annex_existing "$REMOTE"; done; }
annex_missingn()  { for REMOTE in ${@:-$(annex_remotes) .}; do echo "*** Missing in $REMOTE ***"; annex_missing "$REMOTE"; done; }
annex_wantgetn()  { for REMOTE in ${@:-$(annex_remotes) .}; do echo "*** Want-get in $REMOTE ***"; annex_wantget "$REMOTE"; done; }
annex_wantdropn() { for REMOTE in ${@:-$(annex_remotes) .}; do echo "*** Want-drop in $REMOTE ***"; annex_wantdrop "$REMOTE"; done; }
annex_existingnc() { for REMOTE in ${@:-$(annex_remotes) .}; do echo -n "Num existing in $REMOTE : "; annex_existing "$REMOTE" | wc -l; done; }
annex_missingnc()  { for REMOTE in ${@:-$(annex_remotes) .}; do echo -n "Num missing in $REMOTE : "; annex_missing "$REMOTE" | wc -l; done; }
annex_wantgetnc()  { for REMOTE in ${@:-$(annex_remotes) .}; do echo -n "Num want-get in $REMOTE : "; annex_wantget "$REMOTE" | wc -l; done; }
annex_wantdropnc() { for REMOTE in ${@:-$(annex_remotes) .}; do echo -n "Num want-drop in $REMOTE : "; annex_wantdrop "$REMOTE" | wc -l; done; }

# Is file in annex ?
annex_isin() {
  annex_exists || return 1
  local REPO="${1:-.}"
  shift
  [ -n "$(git annex find --in "$REPO" "$@")" ]
}

# Find annex repositories
annex_find_repo() {
	git_find0 "$@" |
		while read -d $'\0' DIR; do
			annex_exists "$DIR" && printf "'%s'\n" "$DIR"
		done 
}

# Set preferred content
annex_preferred() {
  annex_exists || return 1
  local REPO="${1:-.}"
  local REQUIRED_FILE="$(annex_root)/.required"
  local WANTED_FILE="$(annex_root)/.wanted"
  local REQUIRED="${2:-$REQUIRED_FILE}"
  local WANTED="${3:-$WANTED_FILE}"
  if [ -r "$REQUIRED" ]; then
    cat "$REQUIRED" | xargs -r -n2 git annex required
  elif [ "$REQUIRED" != "$REQUIRED_FILE" ]; then
    git annex required "$REPO" "$REQUIRED"
  fi
  if [ -r "$WANTED" ]; then
    cat "$WANTED" | xargs -r -n2 git annex wanted
  elif [ "$WANTED" != "$WANTED_FILE" ]; then
    git annex wanted "$REPO" "$WANTED"
  fi
}

########################################
# Fsck all
annex_fsck() {
  local REMOTES="${1:-. $(annex_remotes)}"
  [ $# -ge 1 ] && shift
  for REMOTE in $REMOTES; do
    [ "$REMOTE" = "." ] &&
      git annex fsck "$@" ||
      git annex fsck --from=${REMOTE} "$@"
  done
}

########################################
# Rename special remotes
annex_rename_special() {
	git config remote.$1.fetch "dummy"
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
annex_fromkey0() {
  for KEY; do
    KEY="$(basename "$KEY")"
    #git show -999999 -p --no-color --word-diff=porcelain -S "$KEY" | 
    #git log -n 1 -p --no-color --word-diff=porcelain -S "$KEY" |
    git log -p --no-color --word-diff=porcelain -S "$KEY" |
      awk '/^(---|\+\+\+) (a|b)/{line=$0} /'$KEY'/{printf "%s\0",substr(line,5)}' |
      # Remove leading/trailing double quotes, leading "a/", trailing spaces. Escape '%'
      sed -z -e 's/\s*$//' -e 's/^"//' -e 's/"$//' -e 's/^..//' -e 's/%/\%/g' |
      # Remove duplicated files
      uniq -z | 
      # printf does evaluate octal charaters from UTF8
      xargs -r0 -n1 -I {} -- printf "{}\0"
      # Sanity extension check between key and file
      #xargs -r0 -n1 sh -c '
        #[ "${1##*.}" != "${2##*.}" ] && printf "Warning: key extension ${2##*.} mismatch %s\n" "${1##*/}" >&2
        #printf "$2\0"
      #' _ "$KEY"
  done
}
annex_fromkey() {
  annex_fromkey0 "$@" | xargs -r0 -n1
}

# Check if key exists in the annex (use the default backend)
annex_key_exists() {
  for KEY; do
    annex_fromkey0 "$KEY" | xargs -r0 git annex find | grep -m 1 -e "." >/dev/null && echo "$KEY"
  done
}

# Check if input file exists in the annex (use the default backend)
annex_file_exists() {
  for FILE; do
    local KEY="$(git annex calckey "$FILE")"
    # Search without the key file extension
    annex_key_exists "${KEY%%.*}" >/dev/null && echo "$KEY $FILE"
  done
}

# Get key from file name
annex_getkey() {
  git annex find --include='*' "${@}" --format='${key}\000'
}
annex_gethashdir() {
  git annex find --include='*' "${@}" --format='${hashdirlower}\000'
}
annex_gethashdirmixed() {
  git annex find --include='*' "${@}" --format='${hashdirmixed}\000'
}
annex_gethashpath() {
  git annex find --include='*' "${@}" --format='${hashdirlower}${key}/${key}\000'
}
annex_gethashpathmixed() {
  git annex find --include='*' "${@}" --format='${hashdirmixed}${key}/${key}\000'
}

########################################
# List unused files
annex_unused() {
  ! annex_bare || return 1
  annex_fromkey0 $(git annex unused ${FROM:+--from $FROM} | awk "/^\s+[0-9]+\s/{print \$2}") |
    xargs -r0 -n1
}
annex_unusedc() {
  annex_unused "$@" | wc -l
}

# List unused files
annex_unused_with_key() {
  ! annex_bare || return 1
  git annex unused ${FROM:+--from $FROM} | grep -E '^\s+[0-9]+\s' |
    while IFS=' ' read -r NUM KEY; do
      echo "Key  : $KEY"
      annex_fromkey0 "$KEY" |
        xargs -r0 -n1 echo "File :"
    done
}

# Group list unused files
annex_unusedn() {
  for REMOTE in ${@:-$(annex_remotes) .}; do
    echo "*** Unused in $REMOTE ***"
    FROM="$REMOTE" annex_unused
  done
}
annex_unusednc() {
  for REMOTE in ${@:-$(annex_remotes) .}; do
    echo -n "Num unused in $REMOTE : "
    FROM="$REMOTE" annex_unused | wc -l
  done
}

# Drop all unused files
annex_dropunused_all() {
  local LAST="$(git annex unused ${FROM:+--from $FROM} | awk '/^\s+[0-9]+\s/ {a=$1} END{print a}')"
  git annex dropunused ${FROM:+--from $FROM} ${FORCE:+--force} "$@" 1-${LAST:?Nothing to drop...}
}

# Drop partially transfered files
annex_dropunused_tmp() {
  git annex unused ${FROM:+--from $FROM} --fast | 
    awk '/^\s+[0-9]+\s+/ {print $1}' | 
    xargs git annex dropunused ${FROM:+--from $FROM} ${FORCE:+--force}
}

# Drop unused files matching pattern
annex_dropunused() {
  ! annex_bare || return 1
  local TMPFILE="$(mktemp)" || return 2
  local IFS="$(printf ' \t\n')"
  local PATTERNS=""
  for ARG; do PATTERNS="${PATTERNS:+$PATTERNS }-e '$ARG'"; done
  git annex unused ${FROM:+--from $FROM} | grep -E '^\s+[0-9]+\s' | 
    while IFS=' ' read -r NUM KEY; do
      annex_fromkey0 "$KEY" |
        eval grep -zF "${PATTERNS:-''}" &&
          echo && 
          echo -en "$NUM " >> "$TMPFILE"
    done
  cat "$TMPFILE" | xargs git annex dropunused ${FROM:+--from $FROM} ${FORCE:+--force} &&
    rm "$TMPFILE" ||
    echo "Dropunused failed using tmp file $TMPFILE"
}

# Drop all unused files interactively
annex_dropunused_interactive() {
  ! annex_bare || return 1
  local IFS="$(printf ' \t\n')"
  local REPLY; read -r -p "Delete unused files? (a/y/n/s) " REPLY
  if [ "$REPLY" = "a" -o "$REPLY" = "A" ]; then
    ${FROM:+FROM="$FROM"} annex_dropunused_all
  elif [ "$REPLY" = "s" -o "$REPLY" = "S" ]; then
    ${FROM:+FROM="$FROM"} annex_listunused
  elif [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
    local LAST="$(git annex unused ${FROM:+--from $FROM} | awk '/^\s+[0-9]+\s/ {a=$1} END{print a}')"
    git annex unused ${FROM:+--from $FROM} | grep -E '^\s+[0-9]+\s' | 
      while read -r NUM KEY; do
        printf "Key: $KEY\nFile: "
        annex_fromkey0 "$KEY"
        echo
        read -r -p "Delete file $NUM/$LAST? (y/f/n) " REPLY < /dev/tty
        if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
          sh -c "git annex dropunused ${FROM:+--from $FROM} ""$@"" $NUM" &
          wait
        elif [ "$REPLY" = "f" -o "$REPLY" = "F" ]; then
          sh -c "git annex dropunused --force ${FROM:+--from $FROM} ""$@"" $NUM" &
          wait
        fi
        echo "~"
      done
  fi
}

########################################
# Clean log by rebuilding branch git-annex & master
# Similar to "git annex forget"
annex_cleanup() {
  # Stop on error
  ( set -e
    annex_exists || return 1
    if [ $(git_st | wc -l) -ne 0 ]; then
      echo "Some changes are pending. Abort ..."
      return 2
    fi
    # Confirmation
    local REPLAY; read -r -p "Cleanup git-annex? (y/n) " REPLY < /dev/tty
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

# Forget a special remote
annex_forget_remote() {
  # Confirmation
  local REPLY; read -r -p "Forget remotes (and cleanup git-annex history)? (y/n) " REPLY < /dev/tty
  [ "$REPLY" != "y" -a "$REPLY" != "Y" ] && return 3
  local OK=1
  for REMOTE; do
    git remote remove "$REMOTE" &&
    git annex dead "$REMOTE" ||
    OK=""
  done
  [ -n "$OK" ] && git annex forget --drop-dead --force
}

########################################
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
# Set a remote key presence flag
# WHERE selects which files & repo to look for
# DBG enable debug mode
annex_setpresentkey() {
  local REMOTE="${1:?No remote specified...}"
  local WHERE="${2:-${WHERE:-*}}"
  local PRESENT="${3:-1}"
  local UUID="$(git config --get remote.${REMOTE}.annex-uuid)"
  [ -z "$UUID" ] && { echo "Remote $REMOTE unknown..." && return 1; }
  eval git annex find --include "$WHERE" --format='\${key}\\000' | xargs -r0 -n1 sh -c '
    DBG="$1"; UUID="$2"; PRESENT="$3"; KEY="$4"
    $DBG git annex setpresentkey "$KEY" "$UUID" $PRESENT
  ' _ "${DBG:+echo [DBG]}" "$UUID" "$PRESENT"
}

########################################
# Find duplicates
annex_duplicates0() {
  local DIR="${1:-.}"
  local FILTER="${2:---all-repeated=separate}"
  git annex find "$DIR" --include '*' --format='${file} ${escaped_key}\000' |
      sort -zk2 | uniq -z $FILTER -f1 |
      sed -z 's/ [^ ]*$//'
}
annex_duplicates() {
  annex_duplicates0 "$@" |
    xargs -r0 -n1
}

# Remove one duplicate
annex_rm_duplicates() {
  annex_duplicates0 "$1" --repeated |
    xargs -r0 git rm
}

########################################
annex_commit_enable() {
  git config --unset "annex.autocommit" false
}
annex_commit_disable() {
  git config --add "annex.autocommit" false
}

########################################
# Annex aliases
alias gana='git annex add'
alias gant='git annex status'
alias gantn='annex_st \\?'
alias gantm='annex_st M'
alias ganl='git annex list'
alias ganls='git annex list'
alias ganlc='git annex find | wc -l'
alias ganf='git annex find'
alias ganfc='git annex find | wc -l'
alias gans='git annex sync'
alias gansn='git annex sync --no-commit'
alias gansp='git annex sync --no-commit --no-push'
alias gansu='git annex sync --no-commit --no-pull'
alias ganss='git annex sync --no-push --no-pull'
alias gansc='git annex sync --content'
alias ganscf='git annex sync --content --fast'
alias gang='git annex get'
alias ganc='git annex copy'
alias ganca='git annex copy --all'
alias gancf='git annex copy --fast'
alias ganct='git annex copy --to'
alias gancat='git annex copy --all --to'
alias gancft='git annex copy --fast --to'
alias gancaf='git annex copy --all --from'
alias gancff='git annex copy --fast --from'
alias gane='git annex export'
alias gand='git annex drop'
alias gandd='git annex forget --drop-dead'
alias gani='git annex info'
alias ganul='git annex unlock'
alias ganup='annex_upload'
alias ganupf='annex_upload --fast'
alias ganm='annex_missing'
alias ganwg='annex_wantget'
alias ganwd='annex_wantdrop'
alias gan='git annex'
# Assistant
alias ganas='git annex assistant'
alias ganw='git annex webapp'

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#annex}" != "$1" ] && "$@" || true
