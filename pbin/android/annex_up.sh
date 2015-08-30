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
ONCHARGE=""

# From now on, run in a subshell because of the exit command
(
    # Check requirements
    if ! command -v git >/dev/null 2>&1; then
        echo "[error] Cannot find git. Abort..."
        exit 1
    fi
    
    # Get arguments
    while getopts "db:l:asc:fw:g" OPTFLAG; do
      case "$OPTFLAG" in
        d) set -vx; DBG="false";;
        b) BASEDIR="${OPTARG}";;
        l) LOGFILE="\"${OPTARG}\"";;
        a) ANNEX_ADD="";;
        s) ANNEX_SYNC="";;
        c) ANNEX_CONTENT="${OPTARG:-$(git remote)}";;
        f) ANNEX_FORCE="--force";;
        w) WIFIDEV="${OPTARG}";;
        g) ONCHARGE="1";;
        *) echo >&2 "Usage: annex.sh [-h] [-d] [-b] [-l logfile] [-a] [-c repos] [-f] [-s dir] [-w device] [-g]"
           echo >&2 "-d  dry-run"
           echo >&2 "-b  set base directory"
           echo >&2 "-l  log to file"
           echo >&2 "-a  skip adding files"
           echo >&2 "-s  skip syncing"
           echo >&2 "-c  repos for which to sync content (not with -s)"
           echo >&2 "-f  force file addition (not with -a)"
           echo >&2 "-w  sync file content only on wifi (not with -s)"
           echo >&2 "-g  proceed only when in charge"
           exit 1
           ;;
      esac
    done
    unset OPTIND OPTFLAG OPTARG

    # Main script
    echo "[annex] start at $(date)"
    if [ ! -z "$ONCHARGE" ] && [ "$(cat /sys/class/power_supply/battery/status | tr '[:upper:]' '[:lower:]')" != "charging" ]; then
        echo "[error] Device is not in charge. Abort..."
        exit 1
    fi
    if [ ! -z "$WIFIDEV" ] && ! ip addr show dev "$WIFIDEV" 2>/dev/null | grep UP >/dev/null; then
        echo "[warning] Wifi device '$WIFIDEV' is not connected. Disable file content syncing..."
        unset ANNEX_CONTENT
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
            echo "[warning] Directory '$PWD' is not git-ready. Skip it..."
            continue
        fi
        if ! git config --get annex.version >/dev/null 2>&1; then
            echo "[warning] Directory '$PWD' is not annex-ready. Skip it..."
            continue
        fi
        if [ ! -z "$ANNEX_ADD" ]; then
            IFS=$'\n'
            for FILE in $(cat "$ANNEX_FILELIST" 2>/dev/null); do
                echo "[annex] Add '$FILE'"
                ${DBG} git annex add "$FILE" $ANNEX_FORCE
            done
        fi
        if [ ! -z "$ANNEX_SYNC" ]; then
            if ! git config --get user.name >/dev/null 2>&1; then
                echo "[annex] Setup local user name and email"
                ${DBG} git config --local user.name "$USER"
                ${DBG} git config --local user.email "$USER@$HOSTNAME"
            fi
            echo "[annex] Sync metadata"
            ${DBG} git annex sync
            for REMOTE in ${ANNEX_CONTENT}; do
                echo "[annex] Sync files content to remote '$REMOTE'"
                ${DBG} git annex copy . --to "$REMOTE"
            done
        fi
    done
    echo "[annex] end at $(date)"
    exit 0
    
) 2>&1 | tee "$LOGFILE"
