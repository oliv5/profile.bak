#!/system/bin/sh
# Add content to annex and sync it
(
    # Local variables
    PATH="/data/data/ga.androidterm/bin:$PATH"
    DBG=""
    BASEDIR="."
    GLOBAL_ANNEX_REPOLIST=".annexlist"
    GLOBAL_ANNEX_FILELIST=".gitlist"
    GLOBAL_ANNEX_CONTENT=""
    GLOBAL_ANNEX_FORCE=""
    GLOBAL_ANNEX_SYNC="1"
    GLOBAL_ANNEX_ADD="1"
    WIFIDEV=""
    LOGFILE="/dev/null"
    ONCHARGE=""

    # Get arguments
    while getopts "db:l:asc:fw:g" OPTFLAG; do
      case "$OPTFLAG" in
        d) set -vx; DBG="false";;
        b) BASEDIR="${OPTARG}";;
        l) LOGFILE="\"${OPTARG}\"";;
        a) GLOBAL_ANNEX_ADD="";;
        s) GLOBAL_ANNEX_SYNC="";;
        c) GLOBAL_ANNEX_CONTENT="${OPTARG}";;
        f) GLOBAL_ANNEX_FORCE="--force";;
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
    
    # Git wrapper
    git() {
        git "$@" 2>&1 | grep -v WARNING
    }

  # Run in a subshell because of the exit command
  (
    # Check requirements
    if ! command -v git >/dev/null 2>&1; then
        echo "[error] Cannot find git. Abort..."
        exit 1
    fi

    # Main script
    echo "[annex] start at $(date)"
    IFS=$'\n'
    for REPO in "$BASEDIR" $(cat "$GLOBAL_ANNEX_REPOLIST" 2>/dev/null); do
        # Select/check a repo
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
        # Setup repo options
        local ANNEX_FILELIST="$GLOBAL_ANNEX_FILELIST"
        local ANNEX_ADD="$GLOBAL_ANNEX_ADD"
        local ANNEX_FORCE="$GLOBAL_ANNEX_FORCE"
        local ANNEX_SYNC="$GLOBAL_ANNEX_SYNC"
        local ANNEX_CONTENT="${GLOBAL_ANNEX_CONTENT:-$(git remote)}"
        # Check options
        if [ ! -z "$ONCHARGE" ] && [ "$(cat /sys/class/power_supply/battery/status | tr '[:upper:]' '[:lower:]')" != "charging" ]; then
            echo "[warning] Device is not in charge. Disable file addition and file content syncing..."
            unset ANNEX_CONTENT ANNEX_ADD
        fi
        if [ ! -z "$WIFIDEV" ] && ! ip addr show dev "$WIFIDEV" 2>/dev/null | grep UP >/dev/null; then
            echo "[warning] Wifi device '$WIFIDEV' is not connected. Disable file content syncing..."
            unset ANNEX_CONTENT
        fi
        # Add files
        if [ ! -z "$ANNEX_ADD" ]; then
            IFS=$'\n'
            for FILE in $(cat "$ANNEX_FILELIST" 2>/dev/null); do
                echo "[annex] Add '$FILE'"
                ${DBG} git annex add "$FILE" $ANNEX_FORCE
            done
        fi
        # Sync files
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
)
