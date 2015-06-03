#!/bin/sh
DBG=""
LOGGER="echo"
NOLOG="true"
CHECKDIR=""
PATH="$PATH:/bin:/usr/bin"

# Rsync options
# Note RSYNC option -x prevent deleting files when using symbolic links
OPT_BACKUP="-b"
OPT_DELETE="--delete --ignore-errors"
OPT_DRYRUN="-n --progress"
OPTS="-v -r -z -s -i --size-only"

# Functions
show(){ $LOGGER "$@"; }
log() { $NOLOG $LOGGER "$@"; }
run() { show "$*"; eval ${DBG} "$@"; }
end() {
    # Log end of backup
    show "Backup - ends at $(date)"
    [ ! -z "$DBG" ] && set +x
    exit ${1:-0}
}

# Beginning
[ ! -z "$DBG" ] && set -x
show "Backup - begins at $(date)"

# Get args
log "Backup - read parameters"
while getopts "bsdntlc:hf:m" FLAG
do
  case "$FLAG" in
    b) OPTS="${OPTS} ${OPT_BACKUP}";;
    s) OPTS="${OPTS} ${OPT_DRYRUN}";;
    d) OPTS="${OPTS} ${OPT_DELETE}";;
    n) DBG="echo";;
    t) OPTS="${OPTS} -T $(mktemp -d)";;
    l) LOGGER="logger"; NOLOG="";;
    c) CHECKDIR="${OPTARG}";;
    f) ;; # for compatibility with old script
    m) ;; # for compatibility with old script
    h) echo >&2 "Usage: `basename $0` [-s] [-d] [-n] [-f fuse] -[m] -- src dst ..."
       echo >&2 "-n   debug mode (no action)"
       echo >&2 "-s   show only (dry run)"
       echo >&2 "-d   delete unknown destination files"
       echo >&2 "-t   use /tmp as temporary storage"
       echo >&2 "-l   use system logger instead of stdout"
       echo >&2 "-c   directory to check mountpoints"
       echo >&2 "...  additional rsync options"
       exit 1
       ;;
  esac
done
shift $(($OPTIND-1))
SRC="${1:?Please specify the source directory}"
DST="${2:?Please specify the target directory}"
SRC="${SRC%/}";DST="${DST%/}"
shift 2
OPTS="${OPTS} $@"

# Check parameters
if [ "$SRC" = "$DST" ]; then
    log "ERROR: same directory specified for both src and dst"
    exit 1
fi

# Check the test file in each directories
log "Backup - check directories"
if [ ! -e "$SRC/$CHECKDIR" -o ! -e "$DST/$CHECKDIR" ]; then
    log "ERROR: couldn't find the test file '$CHECKDIR' in the mount dir '$SRC' & '$DST'"
    end 1
fi

# Backup
log "Backup - starts"
run rsync ${OPTS} "$SRC/" "$DST/"
ERRCODE=$?
log "Backup - done"

# Sync before the end
log "Backup - sync"
sync

# End
end $ERRCODE
