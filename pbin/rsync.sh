#!/bin/sh
DBG=""
LOGGER="echo"
VERBOSE="false"
CHECKMOUNT=""
PATH="$PATH:/bin:/usr/bin"

# Rsync options
# Note RSYNC option -x prevent deleting files when using symbolic links
OPT_BACKUP="-b"
OPT_DELETE="--delete --ignore-errors"
OPT_DRYRUN="-n --progress"
OPTS="-v -r -z -s -i --size-only"

# Subshell
(
    # Functions
    log() { $VERBOSE $LOGGER "$@"; }
    end() { log "Backup - ends at $(date)"; exit ${1:-0}; }

    # Get args
    while getopts "bsdtlvc:hf:m" FLAG
    do
      case "$FLAG" in
        b) OPTS="${OPTS} ${OPT_BACKUP}";;
        s) OPTS="${OPTS} ${OPT_DRYRUN}";;
        d) OPTS="${OPTS} ${OPT_DELETE}";;
        t) OPTS="${OPTS} -T $(mktemp -d)";;
        l) LOGGER="logger"; VERBOSE="";;
        v) VERBOSE="";;
        c) CHECKMOUNT="${OPTARG}";;
        f) ;; # for compatibility with old script
        m) ;; # for compatibility with old script
        h) echo >&2 "Usage: `basename $0` [-s] [-d] [-f fuse] [-m] [-l] [-v] [-c dir] -- src dst ..."
           echo >&2 "-s   show only (dry run)"
           echo >&2 "-d   delete unknown destination files"
           echo >&2 "-t   use /tmp as temporary storage"
           echo >&2 "-l   use system logger instead of stdout"
           echo >&2 "-v   be verbose"
           echo >&2 "-c   mountpoint to check in both src/dst"
           echo >&2 "...  additional rsync options"
           end 1
           ;;
      esac
    done
    shift $(($OPTIND-1))
    SRC="${1:?Please specify the source directory}"
    DST="${2:?Please specify the target directory}"
    SRC="${SRC%/}";DST="${DST%/}"
    shift 2
    OPTS="${OPTS} $@"

    # Beginning
    log "Backup - begins at $(date)"

    # Check parameters
    if [ "$SRC" = "$DST" ]; then
        log "ERROR: same directory specified for both src and dst"
        end 1
    fi

    # Check the mountpoint file when specified
    if [ -n "$CHECKMOUNT" ]; then
        #log "Backup - check mountpoint"
        if [ ! -e "$SRC/$CHECKMOUNT" -o ! -e "$DST/$CHECKMOUNT" ]; then
            log "ERROR: couldn't find the test file '$CHECKMOUNT' in the mount dir '$SRC' or '$DST'"
            end 1
        fi
    fi

    # Backup
    #log "Backup - starts"
    ( [ -n "$VERBOSE" ] && set -vx; ${DBG} rsync ${OPTS} "$SRC/" "$DST/")
    ERRCODE=$?
    #log "Backup - done"

    # Sync before the end
    #log "Backup - sync"
    sync

    # End
    end $ERRCODE
)
