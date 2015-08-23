#!/system/bin/sh
# Add content to annex and sync it
# adb push annex.sh /sdcard/bin

# Local variables
PATH="/data/data/ga.androidterm/bin:$PATH"
DBG=""
SRCDIR="."
ANNEX_FILELIST=".gitlist"
ANNEX_CONTENT=""
ANNEX_FORCE=""
LOGFILE="/dev/null"

# From now on, run in a subshell because of the exit command
(
    # Get arguments
    while getopts "dcfl:s:h" OPTFLAG; do
      case "$OPTFLAG" in
        d) set -vx; DBG="false";;
        c) ANNEX_CONTENT="--content";;
        f) ANNEX_FORCE="--force";;
        l) LOGFILE="\"${OPTARG}\"";;
        s) SRCDIR="${OPTARG}";;
        *) echo >&2 "Usage: annex.sh [-d] [-c] [-f] [-l logfile] [-s dir]"
           echo >&2 "-d  dry-run"
           echo >&2 "-c  sync content"
           echo >&2 "-f  force file addition"
           echo >&2 "-l  log to file"
           echo >&2 "-s  set source directory"
           exit 1
           ;;
      esac
    done
    unset OPTIND OPTFLAG OPTARG

    # Main script
    echo "Annex - begins at $(date)"
    cd "$SRCDIR"
    if ! command -v git >/dev/null 2>&1; then
        echo "Cannot find git. Abort..."
        exit 1
    fi
    if ! git rev-parse --verify "HEAD" >/dev/null 2>&1; then
        echo "Directory '$PWD' is not git-ready. Abort..."
        exit 1
    fi
    if ! git config --get annex.version >/dev/null 2>&1; then
        echo "Directory '$PWD' is not annex-ready. Abort..."
        exit 1
    fi
    if ! git config --get user.name >/dev/null 2>&1; then
        ${DBG} git config --local user.name "$USER"
        ${DBG} git config --local user.email "$USER@$HOSTNAME"
    fi
    IFS=$'\n'
    for FILE in $(cat "$ANNEX_FILELIST"); do
        echo "Add '$FILE'"
        ${DBG} git annex add "$FILE" $ANNEX_FORCE
    done
    ${DBG} git annex sync $ANNEX_CONTENT
    echo "Annex - ends at $(date)"
    exit 0
    
) 2>&1 | tee "$LOGFILE"
