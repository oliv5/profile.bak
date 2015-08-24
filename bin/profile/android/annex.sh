#!/system/bin/sh
# Add content to annex and sync it
# adb push annex.sh /sdcard/bin
PATH="/data/data/ga.androidterm/bin:$PATH"

# Local variables
DBG=""
BASEDIR="."
ANNEX_FILELIST=".gitlist"
ANNEX_REPOLIST=".annexlist"
ANNEX_CONTENT=""
ANNEX_FORCE=""
ANNEX_SYNC="1"
ANNEX_ADD="1"
WIFIDEV=""
LOGFILE="/dev/null"

# From now on, run in a subshell because of the exit command
(
    # Get arguments
    while getopts "db:ascfl:w:" OPTFLAG; do
      case "$OPTFLAG" in
        d) set -vx; DBG="false";;
        b) BASEDIR="${OPTARG}";;
        a) ANNEX_ADD="";;
        s) ANNEX_SYNC="";;
        c) ANNEX_CONTENT="--content";;
        f) ANNEX_FORCE="--force";;
        l) LOGFILE="\"${OPTARG}\"";;
        w) WIFIDEV="${OPTARG}";;
        *) echo >&2 "Usage: annex.sh [-h] [-d] [-b] [-a] [-c] [-f] [-l logfile] [-s dir] [-w device]"
           echo >&2 "-d  dry-run"
           echo >&2 "-b  set base directory"
           echo >&2 "-a  skip adding files"
           echo >&2 "-s  skip syncing"
           echo >&2 "-c  sync content (not with -s)"
           echo >&2 "-f  force file addition (not with -a)"
           echo >&2 "-l  log to file"
           echo >&2 "-w  sync file content only with wifi (not with -s)"
           exit 1
           ;;
      esac
    done
    unset OPTIND OPTFLAG OPTARG

    # Main script
    echo "[annex] start at $(date)"
    if ! command -v git >/dev/null 2>&1; then
        echo "[error] Cannot find git. Abort..."
        exit 1
    fi
    IFS=$'\n'
    for REPO in "$BASEDIR" $(cat "$ANNEX_REPOLIST" 2>/dev/null); do
        echo "[annex] Process repo '$REPO'"
        if [ ! -d "$REPO" ]; then
            echo "[warning] Repo '$REPO' does not exists. Skip it..."
            continue
        fi
        cd "$REPO"
        if ! git rev-parse --verify "HEAD" >/dev/null 2>&1; then
            echo "[error] Directory '$PWD' is not git-ready. Abort..."
            exit 1
        fi
        if ! git config --get annex.version >/dev/null 2>&1; then
            echo "[error] Directory '$PWD' is not annex-ready. Abort..."
            exit 1
        fi
        if [ ! -z "$ANNEX_ADD" ]; then
            IFS=$'\n'
            for FILE in $(cat "$ANNEX_FILELIST"); do
                echo "[annex] Add '$FILE'"
                ${DBG} git annex add "$FILE" $ANNEX_FORCE
            done
        fi
        if [ ! -z "$ANNEX_SYNC" ]; then
            echo "[annex] Sync repo ${ANNEX_CONTENT:+with content}"
            if ! git config --get user.name >/dev/null 2>&1; then
                ${DBG} git config --local user.name "$USER"
                ${DBG} git config --local user.email "$USER@$HOSTNAME"
            fi
            if [ -z "$WIFIDEV" ] || ip addr show dev "$WIFIDEV" 2>/dev/null | grep UP >/dev/null; then
                ${DBG} git annex sync $ANNEX_CONTENT
            else
                echo "[warning] Wifi device '$WIFIDEV' is not connected. Skip file content syncing..."
                ${DBG} git annex sync
            fi
        fi
    done
    echo "[annex] end at $(date)"
    exit 0
    
) 2>&1 | tee "$LOGFILE"
