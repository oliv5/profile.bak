#!/bin/sh

# Environment
export SVN_EDITOR=vim

# Show svn aliases
alias salias='alias | grep -re " s..\?="'

# Status aliases
alias st='svn st | grep . | sort'
alias ss='st | grep -E "^(A|\~|D|M|R|C|\!|---| M)"'
alias sa='st | grep -E "^(A|---)"'
alias sc='st | grep -E "^(C|---|      C)"'
alias sn='st | grep -E "^(\?|\~|---)"'
alias sm='st | grep -E "^(M|R|---)"'
alias sd='st | grep -E "^D"'
alias ssl='ss | cut -c 9-'
alias sal='sa | cut -c 9-'
alias scl='sc | cut -c 9-'
alias snl='sn | cut -c 9-'
alias sml='sm | cut -c 9-'
alias sdl='sd | cut -c 9-'
alias stl='st | cut -c 9-'
alias sst='ss | cut -c 9- | xargs touch'
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
  DIR="$(readlink -m "$(svn-root)/${1:-.svnbackup}/$(basename "$(svn-repo)")$(svn-branch)${2:+_$2}")"
  mkdir -p "${DIR}"
  echo "${DIR}"
}

# Build a backup filename for this repo
svn-bckname() {
  #echo "${1:+$1__}$(basename "$(svn-repo)")__$(basename "$(svn-url)")${2:+__$2}"
  #echo "${1:+$1__}$(basename "$(svn-repo)")__$(basename "$(svn-url)")__$(basename "$PWD")${2:+__$2}"
  echo "${1:+$1__}$(basename "$PWD")${2:+__$2}"
}

# Retrieve date
svn-date() {
  date +%Y%m%d-%H%M%S
}

# Get svn repository path
svn-repo() {
  svn info "$@" | grep "Repository Root:" | grep -oh 'svn.*'
}

# Get svn url name
svn-url() {
  svn info "$@" | grep "URL:" | grep -oh 'svn.*'
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
  svn info "$@" | grep "Revision:" | grep -oh '[0-9]\+'
}

# Get status file list
svn-st() {
  svn st "${@:2}" | grep -E "${1:-^[^ ]}" | cut -c 9-
}

# Extract SVN revisions from string rev0:rev1
_svn-getrev() {
  REV1="${1%%:*}"
  REV2="${1##*:}"
  echo "${REV1:-HEAD} ${REV2:-HEAD}"
}
_svn-getrev1() {
  REV1="${1%%:*}"
  echo "${REV1:-HEAD}"
}
_svn-getrev2() {
  REV2="${1##*:}"
  echo "${REV2:-HEAD}"
}

# Merge 3-way
svn-merge() {
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
      read ANSWER; [ "$ANSWER" = "y" -o "$ANSWER" = "Y" ] && svn resolved "${file}"
    done
  fi
}

# Create a changelist
svn-cl() {
  CL="CL$(svn-date)"
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
  [ $(svn st | grep -E "^[^\?\X\P]" | wc -l) -gt 0 ]
}

# Clean repo, remove unversionned files
svn-clean() {
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
svn-revert() {
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export HEAD HEAD "$(svn-bckdir)/revert_$(svn-bckname)_r$(svn-rev)_$(svn-date).7z"
  # Revert local modifications
  svn revert -R . ${1:+--cl $1} "${@:2}"
}

# Rollback to a previous revision, don't change unversionned files
svn-rollback() {
  # Get target revision number
  REV1=${1:-PREV}
  REV2=${2:-HEAD}
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export $REV1 $REV2 "$(svn-bckdir)/rollback_$(svn-bckname)_r${REV1}-${REV2}_$(svn-date).7z"
  # Rollback (svn merge back)
  svn merge -r $REV1:$REV2 .
}

# Backup current changes
svn-export() {
  # Check we are in a repository
  svn-exists || return
  # Get revisions
  REV1=${1:-HEAD}
  REV2=${2:-HEAD}
  # Get archive path, if not specified
  ARCHIVE="$3"
  if [ -z "$ARCHIVE" ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      REV="$(svn-rev)"
      ARCHIVE="$(svn-bckdir)/export_$(svn-bckname)_r${REV}_$(svn-date).7z"
    else
      # Export changes between the 2 revisions
      ARCHIVE="$(svn-bckdir)/export_$(svn-bckname)_r${REV1}-${REV2}_$(svn-date).7z"
    fi
  fi
  # Get applicable files
  FILES="${@:4}"
  # Create archive, if not existing already
  if [ ! -f $ARCHIVE ]; then
    if [ "$REV1" = "HEAD" ]; then
      # Export changes made upon HEAD
      svn-st "^(A|M|R|\~|\!)" $FILES | xargs --no-run-if-empty 7z a $OPTS_7Z "$ARCHIVE"
      RESULT=$?
    else
      # Export changes between the 2 revisions
      svn diff --summarize -r ${REV1}:${REV2} $FILES | grep -vE "^ " | awk '{ print $2 }' | xargs --no-run-if-empty 7z a $OPTS_7Z "$ARCHIVE"
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
svn-import() {
  # Check parameters
  ARCHIVE="$1"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn-zip)"
    echo "Last archive available: $ARCHIVE"
    echo -n "Use this archive? (y/n): "
    read ANSWER
    if [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ]; then
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
  if svn-export HEAD HEAD "$(svn-bckdir)/suspend_$(svn-bckname)_r$(svn-rev)_$(svn-date).7z" "$@"; then
    svn revert -R "${@:-.}"
  fi
}

# Resume a CL
svn-resume() {
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
  URL="${1}"
  #svn log -q $URL | grep -E -e "^r[[:digit:]]+" -o | cut -c2- | sort -rn | {
  svn log -q $URL | awk '/^r[[:digit:]]+/ {print substr($1,2)}' | {
    if [ ! -z "$URL" -a $# -gt 1 ]; then
      # First revision as full text
      echo
      read r
      svn log -r$r $URL
      svn cat -r$r $URL
      echo
    fi
    # Remaining revisions as differences to previous revision
    while read r
    do
      echo
      svn log -r$r $URL
      svn diff -c$r $URL
      echo
    done
  }
}

# Show user commit
svn-loguser() {
  svn log | sed -n "/${1:-$USER}/,/-----$/ p"
}

# Show logs in a range of revisions (-r and -c allowed)
svn-log() {
  svn log --verbose ${2:+-r $1:}${2:-${1:+-c $1}} ${@:3}
}
svn-shortlog() {
  svn-log $@ | grep -E "^[^ |\.]"
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
svn-diffm() {
  svn-diff ${1:-HEAD} ${2:-PREV} ${@:3} --diff-cmd meld
}
svn-diffl() {
  svn-diff ${1:-HEAD} ${2:-PREV} ${@:3} --summarize
}

# List the archives based on given name
svn-zipls() {
  DIR="$1"
  if [ ! -e "$DIR" ]; then
    DIR="$(svn-bckdir)"
  fi
  find "$DIR" -type f -printf '%T@ %p\n' | sort -rn | head -n 1 | cut -d' ' -f 2-
}

# Returns the last archive found based on given name
svn-zip() {
  svn-zipls "$@" | head -n 1
}

# Diff an archive with current repo
_svn-zipdiff() {
  ARCHIVE="$2"
  if [ -z "$ARCHIVE" ]; then
    ARCHIVE="$(svn-zip)"
  fi
  builtin eval "$1" "." "$ARCHIVE"
  #$1 "." "$ARCHIVE"
}
alias svn-zipdiff='_svn-zipdiff 7zdiff'
alias svn-zipdiffc='_svn-zipdiff 7zdiffd 2>/dev/null | wc -l'
alias svn-zipdiffm='_svn-zipdiff 7zdiffm'
alias svn-zipdiffd='_svn-zipdiff 7zdiffd'
