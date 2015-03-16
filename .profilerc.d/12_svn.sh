#!/bin/sh

# Environment
export SVN_EDITOR=vim

# Show svn aliases
alias salias='alias | grep -re " s..\?="'

# Status aliases
alias st='svn st | sort | grep -v "^$"'
alias ss='st | grep -E "^(A|\~|D|M|R|C|\!|---| M)"'
alias sa='st | grep -E "^(A|---)"'
alias sc='st | grep -E "^(C|---|      C)"'
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
# Misc aliases
alias svn_resolve='svn_merge'
alias svn_cla='svn cl'
alias svn_clr='svn changelist --remove'
# Commit aliases
alias sci='svn ci'
alias scid='svn ci -m "Development commit $(svn_date)"'

# Build a unique backup directory for this repo
svn_bckdir() {
  local DIR="$(readlink -m "$(svn_root)/${1:-.svnbackup}/$(basename "$(svn_repo)")$(svn_branch)${2:+__$2}")"
  echo "${DIR}" | sed -e 's/ /_/g'
  #mkdir -p "${DIR}"
}

# Build a backup filename for this repo
svn_bckname() {
  local PREFIX="$1"; local SUFFIX="$2"; local REV1="$3"; local REV2="$4"
  echo "${PREFIX:+${PREFIX}__}$(basename "$PWD")${REV1:+__r$REV1}${REV2:+-$REV2}__$(svn_date)${SUFFIX:+__$SUFFIX}"
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
  echo "${PWD}$(svn_url | sed -e "s;$(svn_repo);;" -e "s;/[^\/]*;/..;g")"
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
  local ARG1="$1"; shift
  svn st "$@" | awk '/'"${ARG1:-^[^ ]}"'/ {$0=substr($0,9); gsub(/\"/,"\\\"",$0); printf "\"%s\"", $0}'
}
svn_stx() {
  local ARG1="$1"; shift
  #svn st "$@" | awk '/'"${ARG1:-^[^ ]}"'/ {print substr($0,9)}' | tr '\n' '\0'
  svn st "$@" | grep -E "${ARG1:-^[^ ]}" | cut -c 9- | tr '\n' '\0'
}

# Extract SVN revisions from string rev0:rev1
_svn_getrev() {
  local REV1="${1%%:*}"
  local REV2="${1##*:}"
  echo "${REV1:-HEAD} ${REV2:-HEAD}"
}
_svn_getrev1() {
  local REV1="${1%%:*}"
  echo "${REV1:-HEAD}"
}
_svn_getrev2() {
  local REV2="${1##*:}"
  echo "${REV2:-HEAD}"
}

# Merge 3-way
svn_merge() {
#  # Recursive call when no argument is given
#  if [ $# -eq 0 ]; then
#    svn_stx '^C' | while IFS="" read -r -d "" FILE ; do
#      svn_merge "$FILE"
#    done
#    return
#  fi
  # Process each file in conflict
  local FILE
  #for FILE in "${@:-"$(svn_st '^C')"}"; do
  svn_stx '^C' | while IFS="" read -r -d "" FILE ; do
    echo "Processing file ${FILE}"
    local CNT=0
    if [ -f ${FILE}.working ]; then
      CNT=$(ls -1 ${FILE}.*-right.* | wc -l)
      for LINE in $(seq $CNT); do
        local right="$(ls -1 ${FILE}.*-right.* | sort | sed -n ${LINE}p)"
        meld "${right}" "${FILE}" "${FILE}.working" 2>/dev/null
      done
    else
      CNT=$(ls -1 ${FILE}.r* | wc -l)
      for LINE in $(seq $CNT); do
        local rev="$(ls -1 ${FILE}.r* | sort | sed -n ${LINE}p)"
        meld "${rev}" "${FILE}" "${FILE}.mine" 2>/dev/null
      done
    fi
    if [ $CNT -gt 0 ] && test $SVN_YES || askuser "Mark the conflict as resolved? (y/n): " y Y; then
      svn resolved "${FILE}"
    fi
  done
}

# Create a changelist
svn_cl() {
  local CL="CL$(svn_date)"
  svn cl "$CL" "$@"
}

# Commit a changelist
svn_ci() {
  local ARG1="$1"; shift
  svn ci --cl "${ARG1:?No changelist specified...}" "$@"
}

# Check svn repository existenz
svn_exists() {
  svn info "$@" > /dev/null
}

# Tells when repo has been modified
svn_modified() {
  # Avoid ?, X, Performing status on external item at '...'
  [ $(svn_st "^[^\?\X\P]" | wc -l) -gt 0 ]
}

# Clean repo, remove unversionned files
svn_clean() {
  # Check we are in a repository
  svn_exists || return
  # Confirmation
  if test $SVN_YES || ! askuser "Backup unversioned files? (y/n): " n N; then
    # Backup
    svn_zipst "^(\?|\I)" "$(svn_bckdir)/$(svn_bckname clean "" $(svn_rev)).7z"
  fi
  # Remove files not in SVN
  svn_stx "^(\?|\I)" | xargs -0 -p --no-run-if-empty rm -v --one-file-system --
}

# Revert modified files, don't change unversionned files
svn_revert() {
  # Check we are in a repository
  svn_exists || return
  # Backup
  svn_export HEAD HEAD "$(svn_bckdir)/$(svn_bckname revert "" $(svn_rev)).7z"
  # Revert local modifications
  local ARG1="$1"; shift
  svn revert -R . ${ARG1:+--cl $ARG1} "$@"
}

# Rollback to a previous revision, don't change unversionned files
svn_rollback() {
  # Get target revision number
  local REV1=${1:-PREV}
  local REV2=${2:-HEAD}
  # Check we are in a repository
  svn_exists || return
  # Backup
  svn_export $REV1 $REV2 "$(svn_bckdir)/$(svn_bckname rollback "" $REV1 $REV2).7z"
  # Rollback (svn merge back)
  svn merge -r $REV1:$REV2 .
}

# Backup current changes
svn_export() {
  # Check we are in a repository
  svn_exists || return
  # Get revisions
  local REV1=${1:-HEAD}
  local REV2=${2:-HEAD}
  # Get archive path, if not specified
  local ARCHIVE="$3"
  if [ -z "$ARCHIVE" ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      local REV="$(svn_rev)"
      ARCHIVE="$(svn_bckdir)/$(svn_bckname export "" $REV).7z"
    else
      # Export changes between the 2 revisions
      ARCHIVE="$(svn_bckdir)/$(svn_bckname export "" $REV1 $REV2).7z"
    fi
  fi
  # Get applicable files
  shift 3; local FILES="$@"
  # Create archive, if not existing already
  if [ ! -f "$ARCHIVE" ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      svn_zipst "$ARCHIVE" "^(A|M|R|C|\~|\!)" "$@"
      local RESULT=$?
    else
      # Export changes between the 2 revisions
      svn_zipdiff "$ARCHIVE" ${REV1} ${REV2} "$@"
      local RESULT=$?
    fi
  else
    echo "File '$ARCHIVE' exists already..."
    local RESULT=1
  fi
  # cleanup
  return $RESULT
}

# Import a CL from an archive
svn_import() {
  # Check parameters
  local ARCHIVE="$1"
  local PATTERN="${2:-export*}"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn_ziplast 1 "" "$PATTERN")"
    if [ -z "$ARCHIVE" ]; then
      echo "No archive found..."
      return 0
    fi
    echo "Last archive available: $ARCHIVE"
    if test $SVN_YES || ! askuser "Use this archive? (y/n): " y Y; then
      echo "No archive selected..."
      return 0
    fi
  fi
  # Check we are in a repository
  svn_exists || return
  # Extract with full path
  7z x "$ARCHIVE" -o"${3:-./}"
}

# Suspend a CL
svn_suspend() {
  # Export & revert if succeed
  if svn_export HEAD HEAD "$(svn_bckdir)/$(svn_bckname suspend "" $(svn_rev)).7z" "$@"; then
    svn revert -R "${@:-.}"
  fi
}

# Resume a CL
svn_resume() {
  # Look for modified repo
  if svn_modified && test $SVN_YES || ! askuser "Your repository has local changes, proceed anyway? (y/n): " y Y; then
    return
  fi
  # Import CL
  svn_import "$1" "suspend*"
}

# Amend a log message
svn_amend() {
  svn propedit --revprop svn:log -r ${1?Error: please specify a revision}
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
  local URL="${1}" REV1="${2:-1}" REV2="${3:-$(svn_rev)}"
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
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn log --verbose ${ARG2:+-r $ARG1:}${ARG2:-${ARG1:+-c $ARG1}} "$@"
}
svn_shortlog() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn_log ${ARG2:+-r $ARG1:}${ARG2:-${ARG1:+-c $ARG1}} "$@" | grep -E "^[^ |\.]"
}
svn_userlog() {
  local ARG1="$1"; shift
  svn_log "$@" | sed -n "/${ARG1:-$USER}/,/-----$/ p"
}

# Display content of a file (only -r rev allowed)
svn_cat () {
  local ARG1="$1"; shift
  svn cat ${ARG1:+-r $ARG1} "$@"
}

# Display the changes in a file in a range of revisions
# or list changed files in a range of revisions (-r and -c allowed)
svn_diff() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn diff ${ARG2:+-r $ARG1:}${ARG2:-${ARG1:+-c $ARG1}} "$@"
}
svn_diffx() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn diff ${ARG2:+-r $ARG1:}${ARG2:-${ARG1:+-c $ARG1}} "$@" | tr '\n' '\0'
}
svn_diffm() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn_diff ${ARG1:-HEAD} ${ARG2:-PREV} "$@" --diff-cmd meld
}
svn_diffl() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn_diff ${ARG1:-HEAD} ${ARG2:-PREV} "$@" --summarize
}

# Make an archive based on the file status
svn_zipst() {
  local ARG1="$1"; local ARG2="$2"; shift 2
  svn_stx "${ARG2:-^(A|M|R|\~|\!)}" "$@" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn "${ARG1:?No archive file defined}"
}

# Make an archive based on a diff
svn_zipdiff() {
  local ARG1="$1"; shift
  svn_diffx "$@" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn "${ARG1:?No archive file defined}"
}

# List the archives based on given name
svn_zipls() {
  local DIR="$1"
  local FILE="${2:-*}"
  if [ ! -d "$DIR" ]; then
    DIR="$(svn_bckdir)"
  fi
  find "$DIR" -type f -name "$FILE" -printf '%T@ %p\n' | sort -rn | cut -d' ' -f 2-
}

# Returns the last archive found based on given name
svn_ziplast() {
  local ARG1="$1"; shift
  svn_zipls "$@" | head -n ${ARG1:-1}
}

# Diff an archive with current repo
__svn_diffzip() {
  local ARCHIVE="$2"
  if [ ! -f "$ARCHIVE" ]; then
    ARCHIVE="$(svn_ziplast 1 "" "${ARCHIVE:-"*$(basename "$PWD")*"}")"
  fi
  # Warning: eval remove one level of quotes
  eval "$1" "." "\"$ARCHIVE\""
}
alias svn_diffzip='__svn_diffzip _7zdiff'
alias svn_diffzipc='__svn_diffzip _7zdiffd 2>/dev/null | wc -l'
alias svn_diffzipm='__svn_diffzip _7zdiffm'
alias svn_diffzipd='__svn_diffzip _7zdiffd'