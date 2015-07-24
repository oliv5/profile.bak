#!/bin/sh
# Script dependencies
rc_sourcemod "shell fct diff 7z"

# Environment
export SVN_EDITOR=vim

# Show svn aliases
alias salias='alias | grep -re " s..\?="'

# Status aliases
alias st='svn st | grep -v "^$"'
alias ss='st | grep -E "^(A|\~|D|M|R|C|\!|---| M)"'
alias sa='st | grep -E "^(A|---)"'
alias sc='st | grep -E "^.? {0,7}C"'
alias sn='st | grep -E "^(\?|\~|---)"'
alias sm='st | grep -E "^(M|R|---)"'
alias sd='st | grep -E "^(D|!)"'
alias ssl='ss | cut -c 9-'
alias sal='sa | cut -c 9-'
alias scl='sc | cut -c 9-'
alias snl='sn | cut -c 9-'
alias sml='sm | cut -c 9-'
alias sdl='sd | cut -c 9-'
alias stl='st | cut -c 9-'
# ls aliases
alias sls='svn ls --depth infinity'
# diff aliases
alias sdd='svn diff'
alias sds='svn diff --summarize'
alias sdm='svn diff --diff-cmd meld'
# Changelist
alias scl='svn cl'
alias sclr='svn changelist --remove'
# Commit aliases
alias sci='svn ci'
alias scid='svn ci -m "Development commit $(svn_date)"'
# jump aliases
alias sr='cd "$(svn_root)"'

# Ask user
svn_askuser() {
  # Warning: don't put a pipe after ask_question or the return code will be modified
  test "${SVN_YES}" || ask_question "$@"
}

# Build a unique backup directory for this repo
svn_bckdir() {
  local DIR="$(readlink -m "$(svn_root)/../${1:-.svnbackup}/$(basename "$(svn_repo)")$(svn_branch)${2:+__$2}")"
  echo "${DIR}" | sed -e 's/ /_/g'
  #mkdir -p "${DIR}"
}

# Build a backup filename for this repo
svn_bckname() {
  local PREFIX="$1" SUFFIX="$2" REV="$3" DATE="${4:-$(svn_date)}"
  echo "${PREFIX:+${PREFIX}__}$(basename "$PWD")$(__svn_revarg "$REV" "__" "-")${DATE:+__$DATE}${SUFFIX:+__$SUFFIX}"
}

# Retrieve date
svn_date() {
  date +%Y%m%d-%H%M%S
}

# Get svn repository path
svn_repo() {
  svn info "$@" | awk 'NR==3 {print $NF}'
}

# Get svn url name
svn_url() {
  svn info "$@" | awk 'NR==2 {print $NF}'
}

# Get path to svn current root
svn_root() {
  #echo "${PWD}$(svn_url | sed -e "s;$(svn_repo);;" -e "s;/[^\/]*;/..;g")"
  _bfind "${1:+$1/}.svn"
}

# Get svn current branch
svn_branch() {
  svn_url | sed -e "s;$(svn_repo);;"
}

# Get svn repository revision
svn_rev() {
  svn info "$@" | awk 'NR==5 {print $NF}'
}

# Get status file list
svn_st() {
  local ARG1="$1"; shift $(min 1 $#)
  #svn st "$@" | awk '/'"${ARG1:-^[^ ]}"'/ {$0=substr($0,9); gsub(/\"/,"\\\"",$0); printf "\"%s\"\n", $0}'
  svn st "$@" | grep -E "${ARG1:-^[^ ]}" | cut -c 9- | sed -E 's/^(.*)$/"\1"/'
}
svn_stx() {
  local ARG1="$1"; shift $(min 1 $#)
  svn st "$@" | grep -E "${ARG1:-^[^ ]}" | cut -c 9- | tr '\n' '\0'
}

# Get svn revision numbers
__svn_rev1() { local REV="${1%%:*}"; [ ! -z "${REV}" ] && echo "${REV}"; }
__svn_rev2() { local REV="${1##*:}"; [ ! -z "${REV}" ] && echo "${REV}"; }
__svn_revarg() {
  local REV="$(echo $1 | sed -r 's/-/:/g')"
  if [ "${REV##*:}" = "$REV" ]; then 
    echo "${REV:+${2:--}c$REV}"
  else 
    echo "${2:--}r${REV}" | sed -r 's/r:/r1:/; s/:$/:HEAD/; s/:/'"${3:-:}"'/'
  fi
}

# Merge 3-way
alias svn_resolve='svn_merge'
svn_merge() {
  local FILE
  # Process each file in conflict or in command line
  svn_stx '^C' "$@" | while IFS="" read -r -d "" FILE ; do
    echo "Processing file ${FILE}"
    local CNT=0
    if [ -f "${FILE}.working" ]; then
      CNT=$(ls -1 "${FILE}".*-right.* | wc -l)
      for LINE in $(seq $CNT); do
        local right="$(ls -1 "${FILE}".*-right.* | sort | sed -n ${LINE}p)"
        echo "  -> compare working with ${right}"
        meld "${right}" "${FILE}" "${FILE}.working" 2>/dev/null
      done
    else
      CNT=$(ls -1 "${FILE}".r* | wc -l)
      for LINE in $(seq $CNT); do
        local rev="$(ls -1 "${FILE}".r* | sort | sed -n ${LINE}p)"
        echo "  -> compare mine with ${rev}"
        meld "${rev}" "${FILE}" "${FILE}.mine" 2>/dev/null
      done
    fi
    # ISSUE HERE: when using read => it gets the value from svn_stx read statement
    sleep 1
  done
}

# Mark files as resolved
svn_resolved() {
  local SVN_ASKUSER=""
  local FILE
  exec 7<&0
  # Process each file in conflict or in command line
  svn_stx "^.? {0,7}C" "$@" | while IFS="" read -r -d "" FILE ; do
    if [ "$SVN_ASKUSER" = "a" ] || { echo "Processing file ${FILE}"; SVN_ASKUSER=$(svn_askuser 7 "  -> mark the conflict as resolved? (a/y/n): " a A y Y); }; then
      svn resolved "${FILE}"
    fi
  done
  exec 7<&-
}

# Create a changelist
svn_cl() {
  local CL="CL$(svn_date)"
  svn cl "$CL" "$@"
}

# Commit a changelist
svn_ci() {
  local ARG1="$1"; shift $(min 1 $#)
  svn ci --cl "${ARG1:?No changelist specified...}" "$@"
}

# Check svn repository existenz
svn_exists() {
  svn info "$@" >/dev/null 2>&1
}

# Tells when repo has been modified
svn_modified() {
  # Avoid ?, X, Performing status on external item at '...'
  [ $(svn_st "^[^\?\X\P]" | wc -l) -gt 0 ]
}

# Clean repo, remove unversionned files
svn_clean() {
  # Check we are in a repository
  svn_exists || return 1
  # Confirmation
  if ! svn_askuser "Backup unversioned files? (y/n): " n N >/dev/null; then
    # Backup
    ARCHIVE="$(svn_bckdir)/$(svn_bckname clean "" $(svn_rev)).7z"
    svn_zipst "$ARCHIVE" "^(\?|\I)"
    if [ ! -f "$ARCHIVE" ]; then
      echo "Error: no archive created..."
      return 1
    fi
  fi
  # Remove files not in SVN (exclude .*)
  svn_stx "^(\?|\I).{7}[^.]" | xargs -0 -p --no-run-if-empty rm -r -v --one-file-system --
}

# Revert modified files, don't change unversionned files
svn_revert() {
  # Check we are in a repository
  svn_exists || return 1
  # Backup
  svn_export "" "$(svn_bckdir)/$(svn_bckname revert "" $(svn_rev)).7z"
  # Revert local modifications
  local ARG1="$1"; shift $(min 1 $#)
  svn revert -R . ${ARG1:+--cl $ARG1} "$@"
}

# Rollback to a previous revision, don't change unversionned files
svn_rollback() {
  # Get target revision number
  local REV="${1:-HEAD:PREV}"
  # Check we are in a repository
  svn_exists || return 1
  # Backup
  svn_export "$REV" "$(svn_bckdir)/$(svn_bckname rollback "" "$REV").7z"
  # Rollback (svn merge back from first to second)
  svn merge $(__svn_revarg "$REV") .
}

# Backup current changes
svn_export() {
  # Check we are in a repository
  svn_exists || return 1
  # Get revisions
  local REV="$1"
  # Get archive path - exit when it exists already
  local ARCHIVE="${2:-$(svn_bckdir)/$(svn_bckname export "" "${REV:-$(svn_rev)}").7z}"
  if [ -e "$ARCHIVE" ]; then
    echo "File '$ARCHIVE' exists already..."
    return 1
  fi
  # Shift already red arguments
  shift $(min 2 $#)
  # Create archive, if not existing already
  if [ -z "$REV" ]; then
    # Export changes made upon HEAD
    svn_zipst "$ARCHIVE" "^(A|M|R|C|\~|\!)" "$@"
  else
    # Export changes between the 2 revisions
    svn_zipdiff "$ARCHIVE" "${REV}" "$@"
  fi
}

# Import a CL from an archive
svn_import() {
  # Check parameters
  local ARCHIVE="$1"
  local PATTERN="${2:-export*}"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn_ziplast 1 "" "$PATTERN")"
    false ${ARCHIVE:?No archive found...}
    echo "Last archive available: $ARCHIVE"
    if ! svn_askuser "Use this archive? (y/n): " y Y >/dev/null; then
      echo "Cancelled by the user..."
      return 1
    fi
  fi
  # Check we are in a repository
  svn_exists || return 1
  # Extract with full path
  7z x "$ARCHIVE" -o"${3:-./}"
}

# Suspend a CL
svn_suspend() {
  # Export & revert if succeed
  if svn_export "" "$(svn_bckdir)/$(svn_bckname suspend "" $(svn_rev)).7z" "$@"; then
    svn revert -R "${@:-.}"
  fi
}

# Resume a CL
svn_resume() {
  # Look for modified repo
  if svn_modified && ! svn_askuser "Your repository has local changes, proceed anyway? (y/n): " y Y >/dev/null; then
    echo "Cancelled by the user..."
    return 1
  fi
  # Import CL
  svn_import "$1" "suspend*"
}

# Amend a log message
svn_amend() {
  svn propedit --revprop svn:log -r ${1?Error: please specify a revision}
}

# Set a file mime property
# Useful for binary files
svn_setmime() {
  for FILE; do
    MIME=$(mimetype -b "$FILE")
    svn propset svn:mime-type "$MIME" "$FILE"
  done
}

# Get a single file
svn_get() {
  svn export "$@" "./$(filename $1)"
}

# Edit svn global config
svn_config() {
  vi "${HOME}/.subversion/config"
}

# Print the history of a file
svn_history() {
  local URL="$1"
  local REV1="$(__svn_rev1 "$2" || echo 1)"
  local REV2="$(__svn_rev2 "$2" || echo $(svn_rev))"
  svn log -q "$URL" | awk '/^r/ {REV=substr($1,2); if (REV>='$REV1' && REV<='$REV2') print REV}' | {
    # Show diffs
    while read r
    do
      echo
      svn log -r$r "$URL" 2>/dev/null
      svn diff -c$r "$URL" 2>/dev/null
      echo
    done
  }
}

# Show logs in a range of revisions (-r and -c allowed)
svn_log() {
  local ARG1="$1"; shift $(min 1 $#)
  svn log $(__svn_revarg "$ARG1") "$@" --verbose
}
svn_shortlog() {
  svn_log "$@" | grep -E "^[^ |\.]"
}
svn_userlog() {
  local ARG1="$1"; shift $(min 1 $#)
  svn_log "$@" | sed -n "/${ARG1:-$USER}/,/-----$/ p"
}

# Display content of a file (only -r rev allowed)
svn_cat () {
  local ARG1="$1"; shift $(min 1 $#)
  svn cat ${ARG1:+-r $ARG1} "$@"
}

# Display the changes in a file in a range of revisions
# or list changed files in a range of revisions (-r and -c allowed)
svn_diff() {
  local ARG1="$1"; shift $(min 1 $#)
  svn diff $(__svn_revarg "$ARG1") "$@"
}
svn_diffm()  { svn_diff "$@" --diff-cmd meld; }
svn_diffl()  { svn_diff "$@" --summarize; }
svn_difflx() { svn_diffl "$@" | grep -E "^[^ D]" | cut -c 9- | tr '\n' '\0'; }

# Make a diff between the current branch and another one
# Only for modified files
__svn_diffb() {
  local FILE
  local ARG1="${1:-true}"; local ARG2="${2:-.}"; shift $(min 2 $#)
  # Process each file in conflict or in command line
  svn_stx '^(A|M|R|C|\~|\!)' "$@" | while IFS="" read -r -d "" FILE ; do
    # Warning: eval remove one level of quotes
    diff -q "$ARG2/$FILE" "$FILE" >/dev/null && {
      echo "Skip file ${FILE}"
    } || {
      echo "Diff file ${FILE}"
      eval "$ARG1" '"$FILE"' '"$ARG2/$FILE"'
      sleep 1
    }
  done
}
alias svn_diffb='__svn_diffb diff'
alias svn_diffbm='__svn_diffb meld'
svn_diffbc() {
  __svn_diffb "true" "$@" | grep -v "Skip" | wc -l
}

# Make an archive based on the file status
svn_zipst() {
  local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#)
  svn_stx "${ARG2:-^(A|M|R|\~|\!)}" "$@" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn -xr!. "${ARG1:?No archive file defined}"
}

# Make an archive based on a diff
svn_zipdiff() {
  local ARG1="$1"; shift $(min 1 $#)
  local PATCH="diff$(__svn_revarg "$1" "_" "-").patch"
  svn_diff "$@" > "$PATCH"
  svn_difflx "$@" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn "${ARG1:?No archive file defined}" "$PATCH"
  #rm "$PATCH"
}

# List the archives based on given name
svn_zipls() {
  local DIR="$1"
  local FILE="${2:-*$(svn_bckname "" "" "" "*")}"
  if [ ! -d "$DIR" ]; then
    DIR="$(svn_bckdir)"
  fi
  find "$DIR" -type f -name "$FILE" -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f 2-
}

# Returns the last archive found based on given name
svn_ziplast() {
  local ARG1="$1"; shift $(min 1 $#)
  svn_zipls "$@" | head -n ${ARG1:-1}
}

# Diff an archive with current repo
__svn_diffzip() {
  local ARCHIVE="$2"
  if [ ! -f "$ARCHIVE" ]; then
    ARCHIVE="$(svn_ziplast 1 "" "${ARCHIVE:-"*$(basename "$PWD")__*"}")"
  fi
  false ${ARCHIVE:?No archive found...}
  # Warning: eval remove one level of quotes
  eval "$1" "." '"$ARCHIVE"'
}
alias svn_diffzip='__svn_diffzip _7zdiff'
alias svn_diffzipc='__svn_diffzip _7zdiffd 2>/dev/null | wc -l'
alias svn_diffzipm='__svn_diffzip _7zdiffm'
alias svn_diffzipd='__svn_diffzip _7zdiffd'
