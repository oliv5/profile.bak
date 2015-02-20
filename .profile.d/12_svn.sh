#!/bin/sh

# Environment
export SVN_EDITOR=vim

# Show svn aliases
alias salias='alias | grep -re " s..\?="'

# Status aliases
alias st='svn st | sort'
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
alias svn-resolve='svn-merge'
alias svn-cl-add='svn cl'
alias svn-cl-rm='svn changelist --remove'
# Commit aliases
alias sci='svn ci'
alias scid='svn ci -m "Development commit $(svn-date)"'

# Build a unique backup directory for this repo
svn-bckdir() {
  local DIR="$(readlink -m "$(svn-root)/${1:-.svnbackup}/$(basename "$(svn-repo)")$(svn-branch)${2:+__$2}")" 
  #mkdir -p "${DIR}"
  echo "${DIR}" | sed -e 's/ /_/g'
}

# Build a backup filename for this repo
svn-bckname() {
  local PREFIX="$1"; local SUFFIX="$2"; local REV1="$3"; local REV2="$4"
  echo "${PREFIX:+${PREFIX}__}$(basename "$PWD")${REV1:+__r$REV1}${REV2:+-$REV2}__$(svn-date)${SUFFIX:+__$SUFFIX}" | sed -e 's/ /_/g'
}

# Retrieve date
svn-date() {
  date +%Y%m%d-%H%M%S
}

# Get svn repository path
svn-repo() {
  svn info "$@" | awk 'NR==3 {print $NF}'
}

# Get svn url name
svn-url() {
  svn info "$@" | awk 'NR==2 {print $NF}'
}

# Get path to svn current root
svn-root() {
  echo "${PWD}$(sed -e "s;$(svn-repo);;" -e "s;/[^\/]*;/..;g" <<< $(svn-url))"
}

# Get svn current branch
svn-branch() {
  sed -e "s;$(svn-repo);;" <<< "$(svn-url)"
}

# Get svn repository revision
svn-rev() {
  svn info "$@" | awk 'NR==5 {print $NF}'
}

# Get status file list
svn-st() {
  svn st "${@:2}" | awk '/'"${1:-^[^ ]}"'/ {$0=substr($0,9); gsub(/\"/,"\\\"",$0); print "\""$0"\""}'
}
svn-stx() {
  #svn st "${@:2}" | awk '/'"${1:-^[^ ]}"'/ {print substr($0,9)}' | tr '\n' '\0'
  svn st "${@:2}" | grep -E "${1:-^[^ ]}" | cut -c 9- | tr '\n' '\0'
}

# Extract SVN revisions from string rev0:rev1
_svn-getrev() {
  local REV1="${1%%:*}"
  local REV2="${1##*:}"
  echo "${REV1:-HEAD} ${REV2:-HEAD}"
}
_svn-getrev1() {
  local REV1="${1%%:*}"
  echo "${REV1:-HEAD}"
}
_svn-getrev2() {
  local REV2="${1##*:}"
  echo "${REV2:-HEAD}"
}

# Merge 3-way
svn-merge() {
#  # Recursive call when no argument is given
#  if [ $# -eq 0 ]; then
#    svn-stx '^C' | while IFS="" read -r -d "" FILE ; do
#      svn-merge "$FILE"
#    done
#    return
#  fi
  # Process each file in conflict
  local FILE
  for FILE in "${@:-"$(svn-st '^C')"}"; do
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
    if [ $CNT -gt 0 ] && $SVN_YES askme "Mark the conflict as resolved? (y/n): " y Y; then
      svn resolved "${FILE}"
    fi
  done
}

# Create a changelist
svn-cl() {
  local CL="CL$(svn-date)"
  svn cl "$CL" "$@"
}

# Commit a changelist
svn-ci() {
  svn ci --cl "${1:?No changelist specified...}" "${@:2}"
}

# Check svn repository existenz
svn-exists() {
  svn info "$@" > /dev/null
}

# Tells when repo has been modified
svn-modified() {
  # Avoid ?, X, Performing status on external item at '...'
  [ $(svn-st "^[^\?\X\P]" | wc -l) -gt 0 ]
}

# Clean repo, remove unversionned files
svn-clean() {
  # Check we are in a repository
  svn-exists || return
  # Confirmation
  if $SVN_YES ! askme "Backup unversioned files? (y/n): " n N; then
    # Backup
    svn-zipst "^(\?|\I)" "$(svn-bckdir)/$(svn-bckname clean "" $(svn-rev)).7z"
  fi
  # Remove files not in SVN
  svn-stx "^(\?|\I)" | xargs -0 --no-run-if-empty rm -Iv
}

# Revert modified files, don't change unversionned files
svn-revert() {
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export HEAD HEAD "$(svn-bckdir)/$(svn-bckname revert "" $(svn-rev)).7z"
  # Revert local modifications
  svn revert -R . ${1:+--cl $1} "${@:2}"
}

# Rollback to a previous revision, don't change unversionned files
svn-rollback() {
  # Get target revision number
  local REV1=${1:-PREV}
  local REV2=${2:-HEAD}
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export $REV1 $REV2 "$(svn-bckdir)/$(svn-bckname rollback "" $REV1 $REV2).7z"
  # Rollback (svn merge back)
  svn merge -r $REV1:$REV2 .
}

# Backup current changes
svn-export() {
  # Check we are in a repository
  svn-exists || return
  # Get revisions
  local REV1=${1:-HEAD}
  local REV2=${2:-HEAD}
  # Get archive path, if not specified
  local ARCHIVE="$3"
  if [ -z "$ARCHIVE" ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      local REV="$(svn-rev)"
      ARCHIVE="$(svn-bckdir)/$(svn-bckname export "" $REV).7z"
    else
      # Export changes between the 2 revisions
      ARCHIVE="$(svn-bckdir)/$(svn-bckname export "" $REV1 $REV2).7z"
    fi
  fi
  # Get applicable files
  local FILES="${@:4}"
  # Create archive, if not existing already
  if [ ! -f "$ARCHIVE" ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      svn-zipst "$ARCHIVE" "^(A|M|R|C|\~|\!)" "$FILES"
      local RESULT=$?
    else
      # Export changes between the 2 revisions
      svn-zipdiff "$ARCHIVE" ${REV1} ${REV2} "$FILES"
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
svn-import() {
  # Check parameters
  local ARCHIVE="$1"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn-ziplast)"
    echo "Last archive available: $ARCHIVE"
    if ! $SVN_YES askme "Use this archive? (y/n): " y Y; then
      echo "No archive selected..."
      return 0
    fi
  fi
  # Check we are in a repository
  svn-exists || return
  # Extract with full path
  7z x "$ARCHIVE" -o"${2:-./}"
}

# Suspend a CL
svn-suspend() {
  # Export & revert if succeed
  if svn-export HEAD HEAD "$(svn-bckdir)/$(svn-bckname suspend "" $(svn-rev)).7z" "$@"; then
    svn revert -R "${@:-.}"
  fi
}

# Resume a CL
svn-resume() {
  # Look for modified repo
  if svn-modified && ! $SVN_YES askme "Your repository has local changes, proceed anyway? (y/n): " y Y; then
    return
  fi
  # Import CL
  svn-import "$1"
}

# Amend a log message
svn-amend() {
  svn propedit --revprop svn:log -r ${1?Error: please specify a revision}
}

# Get a single file
svn-get() {
  svn export "$@" "./$(filename $1)"
}

# Edit svn global config
svn-config() {
  vi "${HOME}/.subversion/config"
}

# Print the history of a file
svn-history() {
  local URL="${1}" REV1="${2:-1}" REV2="${3:-$(svn-rev)}"
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
svn-log() {
  svn log --verbose ${2:+-r $1:}${2:-${1:+-c $1}} ${@:3}
}
svn-shortlog() {
  svn-log ${2:+-r $1:}${2:-${1:+-c $1}} ${@:3} | grep -E "^[^ |\.]"
}
svn-userlog() {
  svn-log ${@:2} | sed -n "/${1:-$USER}/,/-----$/ p"
}

# Display content of a file (only -r rev allowed)
svn-cat () {
  svn cat ${1:+-r $1} ${@:2}
}

# Display the changes in a file in a range of revisions
# or list changed files in a range of revisions (-r and -c allowed)
svn-diff() {
  svn diff ${2:+-r $1:}${2:-${1:+-c $1}} ${@:3}
}
svn-diffx() {
  svn diff ${2:+-r $1:}${2:-${1:+-c $1}} ${@:3} | tr '\n' '\0'
}
svn-diffm() {
  svn-diff ${1:-HEAD} ${2:-PREV} ${@:3} --diff-cmd meld
}
svn-diffl() {
  svn-diff ${1:-HEAD} ${2:-PREV} ${@:3} --summarize
}

# Make an archive based on the file status
svn-zipst() {
  svn-stx "${2:-^(A|M|R|\~|\!)}" "${3}" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn "${1:?No archive file defined}"
}

# Make an archive based on a diff
svn-zipdiff() {
  svn-diffx "${@:2}" | xargs -0 --no-run-if-empty 7z a $OPTS_7Z -xr!.svn "${1:?No archive file defined}"
}

# List the archives based on given name
svn-zipls() {
  local DIR="$1"
  if [ ! -e "$DIR" ]; then
    DIR="$(svn-bckdir)"
  fi
  find "$DIR" -type f -printf '%T@ %p\n' | sort -rn | head -n 1 | cut -d' ' -f 2-
}

# Returns the last archive found based on given name
svn-ziplast() {
  svn-zipls "$@" | head -n 1
}

# Diff an archive with current repo
_svn-diffzip() {
  local ARCHIVE="$2"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn-ziplast)"
  fi
  builtin eval "$1" "." "$ARCHIVE"
  #$1 "." "$ARCHIVE"
}
alias svn-diffzip='_svn-diffzip 7zdiff'
alias svn-diffzipc='_svn-diffzip 7zdiffd 2>/dev/null | wc -l'
alias svn-diffzipm='_svn-diffzip 7zdiffm'
alias svn-diffzipd='_svn-diffzip 7zdiffd'
