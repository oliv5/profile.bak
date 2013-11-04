#!/bin/sh

# Environment
export SVN_EDITOR=vim

# Aliases
alias salias='alias | grep -re " s..\?="'
alias ss='svn st | grep -E "^(A|\~|D|M|R|C|\!|---) | sort"'
alias sa='svn st | grep -E "^(A|---) | sort"'
alias sc='svn st | grep -E "^(C|---) | sort"'
alias sn='svn st | grep -E "^(\?|\~|---) | sort"'
alias sm='svn st | grep -E "^(M|R|---) | sort"'
alias sd='svn st | grep -E "^D | sort"'
alias st='svn st | sort'
alias sl='svn ls --depth infinity'
alias sdd='svn diff'
alias sdm='svn-meld'
alias sds='svn diff --summarize'

# Returns backup directory
function svn-getbackup() {
  ROOT="${SVN_ROOT:-$PWD}"
  DST=$(readlink -m "${ROOT}/../$(basename $ROOT).svnbackup")
  mkdir -p ${DST}
  echo ${DST}
}

# Retrieve date
function svn-date() {
  date +%Y%m%d_%H%M%S
}

# Get status file list
function svn-st() {
  svn st | grep -E "${1:-^[^ ]}" | cut -c 9-
}

# SVN diff with meld
function svn-meld() {
  svn diff --diff-cmd meld "$@"
}

# Merge 3-way
function svn-merge() {
  if [ -z "$1" ]; then
    export -f svn-merge
    svn-st "^C" | xargs sh -c '[ $# -gt 0 ] && svn-merge "$@"' _
  else
    for file in "$@"; do
      if [ -f ${file}.working ]; then 
        right="$(ls -1 ${file}.*-right.* | sort -r | head -1)"
        meld ${right} ${file} ${file}.working 2>/dev/null
      else
        rev="$(ls -1 ${file}.r* | sort -r | head -1)"
        meld ${rev} ${file} ${file}.mine 2>/dev/null
      fi
    done
  fi
}

# Commit a list of file
function svn-ci() {
  # Create a CL from the filelist
  CL="CL$(svn-date)"
  svn cl "$CL" "$@"
  svn ci --cl "$CL"
}

# Get svn repository path
function svn-repo() {
  svn info "$@" | grep "Repository Root:" | grep -oh 'svn.*'
}

# Get svn repository tree name
function svn-tree() {
  svn info "$@" | grep "Repository Root:" | grep -oh '[^/]*$'
}

# Get svn repository revision
function svn-rev() {
  svn info "$@" | grep "Revision:" | grep -oh '[0-9]\+'
}

# Check svn repository existenz
function svn-exists() {
  svn info "$@" > /dev/null
}

# Clean repo, remove unversionned files
function svn-clean() {
  # Confirmation
  echo -n "We are going to remove unversioned files. Go on? (y/n): "
  read ANSWER; [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ] && exit 0
  # Set backup directory
  DST="$(svn-getbackup)"
  # Backup
  svn-export HEAD HEAD "${DST}/backup_$(svn-date).7z"
  # Remove files not in SVN
  svn-st "^(\?|\I)" | xargs rm -rv
  # Revert local modifications
  svn revert -R .
  # Final update
  svn up
}

# Revert modified files, don't change new files
function svn-revert() {
  # Set backup directory
  DST="$(svn-getbackup)"
  # Check we are in a repository
  svn-exists || return
  # Backup
  svn-export HEAD HEAD "${DST}/backup_$(svn-date).7z"
  # Remove files not in SVN
  svn-st "^(\?|\I)" | xargs rm -rv
}

# Backup current changes
function svn-export() {
  # Set backup directory
  DST="$(svn-getbackup)"
  # Get revisions
  REV0=${1:-HEAD}
  REV1=${2:-HEAD}
  # Check we are in a repository
  svn-exists || return
  # Get archive path, if not specified
  ARCHIVE="$3"
  if [ -z "$ARCHIVE" ]; then
    REPO=$(svn-tree)
    if [ "$REV0" == "HEAD" ]; then
      # Export changes made upon HEAD
      REV=$(svn-rev)
      ARCHIVE="${DST}/${REPO}_r${REV}_$(svn-date).7z"
    else
      # Export changes between the 2 revisions
      ARCHIVE="${DST}/${REPO}_r${REV0}-${REV1}_$(svn-date).7z"
    fi
  fi
  # Create archive, if not existing already
  if [ ! -f $ARCHIVE ]; then
    if [ "$REV0" == "HEAD" ]; then
      # Export changes made upon HEAD
      svn-st "^(A|D|M|R|\~|\!)" | xargs 7z a $OPTS_7Z "$ARCHIVE"
      RESULT=$?
    else
      # Export changes between the 2 revisions
      svn diff --summarize -r ${REV0}:${REV1} | awk '{ print $2 }' | xargs 7z a $OPTS_7Z "$ARCHIVE"
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
  7z x "$1" -o"${SVN_ROOT:-./}"
}

# Suspend a CL
function svn-suspend() {
  if svn-export; then
    svn revert -R .
    svn up
  fi
}

# Resume a CL
function svn-resume() {
  if svn diff --summarize --quiet; then
    svn-import "$1"
  else
    echo "Your repository has local changes. Cannot resume CL safely..."
  fi
}

# Extract a CL and compare with current repo
function svn-compare() {
  # Check parameters
  [ -z "$1" ] && echo "Missing input archive..." && exit 1
  # Check we are in a repository
  svn-exists || return
  # Extract the CL in /tmp
  TEMP="$(mktemp -d)"
  ARCHIVE="$(svn-getbackup)/$1"
  7z x "$ARCHIVE" -o"$TEMP/"
  # Compare with repository
  meld "${2:-.}" "$TEMP"
}

# Amend a log message
function svn-amend() {
  svn propedit --revprop svn:log -r ${1?Error: please specify a revision}
}

# Get a single file
function svn-get() {
  svn export "$@" "./$(filename $1)"
}

# Edit svn global config
function svn-config() {
  vi "${HOME}/.subversion/config"
}

# Print the history of a file
function svn-history() {
  url=${1:?Please specify a file name}
  svn log -q $url | grep -E -e "^r[[:digit:]]+" -o | cut -c2- | sort -n | {
    # First revision as full text
    echo
    read r
    svn log -r$r $url@HEAD
    svn cat -r$r $url@HEAD
    echo
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
