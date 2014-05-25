#!/bin/sh

# Environment
export SVN_EDITOR=vim

# Aliases
alias salias='alias | grep -re " s..\?="'
alias ss='svn st | grep -E "^(A|\~|D|M|R|C|\!|---)"'
alias sa='svn st | grep -E "^(A|---)"'
alias sc='svn st | grep -E "^(C|---)"'
alias sn='svn st | grep -E "^(\?|\~|---)"'
alias sm='svn st | grep -E "^(M|R|---)"'
alias sd='svn st | grep -E "^D"'
alias st='svn st'
alias sl='svn ls --depth infinity'
alias sdd='svn diff'
alias sds='svn diff --summarize'
alias sdm='svn diff --diff-cmd meld'
alias svn-resolve='svn-merge'

# Build a unique backup directory for this repo
function svn-bckdir() {
  DIR=$(basename "$(readlink -m "$PWD")")
  DIR=$(readlink -m "$(svn-root)/${1:-.svnbackup}/$DIR${2:+_$2}")
  mkdir -p "${DIR}"
  echo "${DIR}"
}

# Build a backup filename for this repo
function svn-bckname() {
  echo "${1:+$1_}$(basename $(svn-repo))_$(basename $(svn-url))${2:+_$2}"
}

# Retrieve date
function svn-date() {
  date +%Y%m%d-%H%M%S
}

# Get svn repository path
function svn-repo() {
  svn info "$@" | grep "Repository Root:" | grep -oh 'svn.*'
}

# Get svn url name
function svn-url() {
  svn info "$@" | grep "URL:" | grep -oh 'svn.*'
}

# Get svn current root
function svn-root() {
  echo "${PWD}$(sed -e "s;$(svn-repo);;" -e "s;/[^\/]*;/..;g" <<< $(svn-url))"
}

# Get svn repository revision
function svn-rev() {
  svn info "$@" | grep "Revision:" | grep -oh '[0-9]\+'
}

# Get status file list
function svn-st() {
  svn st "${@:2}" | grep -E "${1:-^[^ ]}" | cut -c 9-
}

# Extract SVN revision from string rev0:rev1
function svn-getrev() {
  REV0="${1%%:*}"
  REV1="${1##*:}"
  echo "${REV0:-HEAD} ${REV1:-HEAD}"
}

# Merge 3-way
function svn-merge() {
  if [ -z "$1" ]; then
    export -f svn-merge
    svn-st "^C" | xargs --no-run-if-empty sh -c 'svn-merge "$@"' _
  else
    for file in "$@"; do
      echo "Processing file ${file}"
      if [ -f ${file}.working ]; then 
        CNT=$(ls -1 ${file}.*-right.* | wc -l)
        for LINE in $(seq $CNT); do
          right="$(ls -1 ${file}.*-right.* | sort | sed -n ${LINE}p)"
          meld "${right}" "${file}" "${file}.working" 2>/dev/null
        done
      else
        CNT=$(ls -1 ${file}.r* | wc -l)
        for LINE in $(seq $CNT); do
          rev="$(ls -1 ${file}.r* | sort | sed -n ${LINE}p)"
          meld "${rev}" "${file}" "${file}.mine" 2>/dev/null
        done
      fi
      echo -n "Mark the conflict as resolved? (y/n): "
      read ANSWER; [ "$ANSWER" == "y" -o "$ANSWER" == "Y" ] && svn resolved "${file}"
    done
  fi
}

# Commit a list of files
function svn-ci() {
  CL="CL$(svn-date)"
  svn cl "$CL" "$@"
  svn ci --cl "$CL"
}

# Make a dev commit of a list of files
function svn-cid() {
  CL="CL$(svn-date)"
  svn cl "$CL" "$@"
  svn ci --cl "$CL" -m "Development commit $(svn-date)"
}

# Create a changelist
function svn-cl() {
  CL="CL$(svn-date)"
  svn cl "$CL" "$@"
}

# Check svn repository existenz
function svn-exists() {
  svn info "$@" > /dev/null
}

# Clean repo, remove unversionned files
function svn-clean() {
  # Check we are in a repository
  svn-exists || return
  # Confirmation
  if [ -z "$SVN_YES" ]; then
    echo -n "Backup unversioned files? (y/n): "
    read ANSWER
    if [ "$ANSWER" != "n" -a "$ANSWER" != "N" ]; then
      # Backup
      svn-st "^(\?|\I)" | xargs --no-run-if-empty 7z a $OPTS_7Z "$(svn-bckdir)/clean_$(svn-bckname)_r$(svn-rev)_$(svn-date).7z"
      echo
    fi
  fi
  # Remove files not in SVN
  svn-st "^(\?|\I)" | xargs --no-run-if-empty rm -rv
}

# Revert modified files, don't change unversionned files
function svn-revert() {
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export HEAD HEAD "$(svn-bckdir)/revert_$(svn-bckname)_r$(svn-rev)_$(svn-date).7z"
  # Revert local modifications
  svn revert -R . ${1:+--cl $1}
}

# Rollback to a previous revision, don't change unversionned files
function svn-rollback() {
  # Get target revision number
  REV=${1:?Please enter a revision number}
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export HEAD $REV "$(svn-bckdir)/rollback_$(svn-bckname)_r${REV}_$(svn-date).7z"
  # Rollback (svn merge back)
  svn merge -r HEAD:$REV .
}

# Backup current changes
function svn-export() {
  # Check we are in a repository
  svn-exists || return
  # Get revisions
  REV0=${1:-HEAD}
  REV1=${2:-HEAD}
  # Get archive path, if not specified
  ARCHIVE="$3"
  if [ -z "$ARCHIVE" ]; then
    if [ "$REV0" == "HEAD" ]; then
      # Export changes made upon HEAD
      REV="$(svn-rev)"
      ARCHIVE="$(svn-bckdir)/export_$(svn-bckname)_r${REV}_$(svn-date).7z"
    else
      # Export changes between the 2 revisions
      ARCHIVE="$(svn-bckdir)/export_$(svn-bckname)_r${REV0}-${REV1}_$(svn-date).7z"
    fi
  fi
  # Get applicable files
  FILES="${@:4}"
  # Create archive, if not existing already
  if [ ! -f $ARCHIVE ]; then
    if [ "$REV0" == "HEAD" ]; then
      # Export changes made upon HEAD
      svn-st "^(A|M|R|\~|\!)" $FILES | xargs --no-run-if-empty 7z a $OPTS_7Z "$ARCHIVE"
      RESULT=$?
    else
      # Export changes between the 2 revisions
      svn diff --summarize -r ${REV0}:${REV1} $FILES | awk '{ print $2 }' | xargs --no-run-if-empty 7z a $OPTS_7Z "$ARCHIVE"
      RESULT=$?
    fi
  else
    echo "File '$ARCHIVE' exists already..."
    RESULT=1
  fi
  # cleanup
  return $RESULT
}

# Import a CL from an archive
function svn-import() {
  # Check parameters
  [ -z "$1" ] && echo "Missing input archive..." && exit 1
  # Check we are in a repository
  svn-exists || return
  # Extract with full path
  7z x "$1" -o"${2:-./}"
}

# Suspend a CL
function svn-suspend() {
  # Export & revert if succeed
  if svn-export HEAD HEAD "$(svn-bckdir)/suspend_$(svn-bckname)_r$(svn-rev)_$(svn-date).7z" "$@"; then
    svn revert -R "${@:-.}"
  fi
}

# Resume a CL
function svn-resume() {
  # Look for modified repo
  if [ -z "$SVN_YES" -a svn-modified ]; then
    echo -n "Your repository has local changes, proceed anyway? (y/n): "
    read ANSWER
    if [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ]; then
      return
    fi
  fi
  # Import CL
  svn-import "$1"
}

# Amend a log message
function svn-amend() {
  svn propedit --revprop svn:log -r ${1?Error: please specify a revision}
}

# Get a single file
function svn-get() {
  svn export "$@" "./$(filename $1)"
}

# Tells when repo has been modified
function svn-modified() {
  # Avoid ?, X, Performing status on external item at '...'
  [ $(svn st | grep -E "^[^\?\X\P]" | wc -l) -gt 0 ]
}

# Edit svn global config
function svn-config() {
  vi "${HOME}/.subversion/config"
}

# Print the history of a file
function svn-history() {
  url="${1:?Please specify a file name}"
  svn log -q $url | grep -E -e "^r[[:digit:]]+" -o | cut -c2- | sort -rn | {
    if [ $# -gt 1 ]; then
      # First revision as full text
      echo
      read r
      svn log -r$r $url@HEAD
      svn cat -r$r $url@HEAD
      echo
    fi
    # Remaining revisions as differences to previous revision
    while read r
    do
      echo
      svn log -r$r $url@HEAD
      svn diff -c$r $url@HEAD
      echo
    done
  }
}

# Show logs in a range of revisions
function svn-log() {
  svn log --verbose ${1:+-r $1}${2:+:$2} ${@:3}
}
function svn-shortlog() {
  svn-log $@ | grep -E "^[^ |\.]"
}

# Display the changes in a file in a range of revisions
# or list changed files in a range of revisions 
function svn-diff() {
  svn diff ${1:+-r $1}${2:+:$2} ${@:3}
}
function svn-diffm() {
  svn-diff $@ --diff-cmd meld
}
function svn-diffl() {
  svn-diff $@ --summarize
}

# Display content of a file
function svn-cat () {
  svn cat ${1:+-r $1}${2:+:$2} ${@:3}
}

# Returns the last archive found based on given name
function svn-ziplast() {
  ls -t1 ${1:-$(svn-bckdir)/*} | head -n 1
}

# Diff an archive with current repo
function _svn-zipdiff() {
  ARCHIVE="$2"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn-ziplast)"
  fi
  $1 "$ARCHIVE"
}
alias svn-zipdiff='_svn-zipdiff 7zdiff'
alias svn-zipdiffm='_svn-zipdiff 7zdiffm'

