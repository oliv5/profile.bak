#!/bin/sh
# Add content to annex and sync it
(
    # Local variables
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
    INCHARGE=""

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
        g) INCHARGE="1";;
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
    unset OPTFLAG OPTARG
    OPTIND=1

    # Redirect output
    {
        # Check requirements
        if ! command -v git >/dev/null 2>&1; then
            echo "[error] Cannot find git. Abort..."
            exit 1
        fi

        # Main script
        echo "[annex] start at $(date)"
        _IFS="$IFS"; IFS=$'\n'
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
            local CHARGE_STATUS="$(cat /sys/class/power_supply/battery/status 2>/dev/null | tr '[:upper:]' '[:lower:]')"
            #local CHARGE_LEVEL="$(dumpsys battery | awk '/level:/ {print $2}')"
            if [ ! -z "$INCHARGE" ] && [ "$CHARGE_STATUS" != "charging" -a "$CHARGE_STATUS" != "full" ]; then
                echo "[warning] Device is not in charge, nor full battery. Disable file addition and file content syncing..."
                unset ANNEX_CONTENT ANNEX_ADD
            fi
            if [ ! -z "$WIFIDEV" ] && ! ip addr show dev "$WIFIDEV" 2>/dev/null | grep UP >/dev/null; then
                echo "[warning] Wifi device '$WIFIDEV' is not connected. Disable file content syncing..."
                unset ANNEX_CONTENT
            fi
            # Add files
            if [ ! -z "$ANNEX_ADD" ]; then
                if [ -r "$ANNEX_FILELIST" ]; then
                    echo "[annex] Add files from '$ANNEX_FILELIST' ${ANNEX_FORCE:+(force)}"
                    IFS=$'\n'
                    for FILE in $(cat "$ANNEX_FILELIST" 2>/dev/null); do
                        echo "[annex] Add '$FILE'"
                        ${DBG} git annex add "$FILE" $ANNEX_FORCE
                    done
                else
                    echo "[annex] Add all files ${ANNEX_FORCE:+(force)}"
                    ${DBG} git annex add . $ANNEX_FORCE
                fi
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
        IFS="$_IFS"
        echo "[annex] end at $(date)"
    } 2>&1 | tee "$LOGFILE"
    exit 0
)
