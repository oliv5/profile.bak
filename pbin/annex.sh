#!/bin/sh
# Add content to annex and sync it
(
    # Local variables
    DBG=""
    BASEDIR="."
    REPOLIST=".annexlist"
    FILELIST=".gitlist"
    ANNEX_CONTENT=""
    ANNEX_FORCE=""
    ANNEX_SYNC="1"
    ANNEX_FAST=""
    ANNEX_ADD="1"
    WIFI_DEVICE=""
    INCHARGE=""
    LOGFILE="/dev/null"

    # Get arguments
    echo "[annex] called with args: $@"
    while getopts "db:l:asc:fuw:g" OPTFLAG; do
      case "$OPTFLAG" in
        d) set -vx; DBG="false";;
        b) BASEDIR="${OPTARG}";;
        l) LOGFILE="\"${OPTARG}\"";;
        a) ANNEX_ADD="";;
        s) ANNEX_SYNC="";;
        c) ANNEX_CONTENT="${OPTARG}";;
        f) ANNEX_FORCE="--force";;
        u) ANNEX_FAST="--fast";;
        w) WIFI_DEVICE="${OPTARG}";;
        g) INCHARGE="1";;
        *) echo >&2 "Usage: annex.sh [-h] [-d] [-b dir] [-l logfile] [-a] [-c repos] [-f] [-u] [-s] [-w device] [-g]"
           echo >&2 "-d  dry-run"
           echo >&2 "-b  set base directory"
           echo >&2 "-l  log to file"
           echo >&2 "-a  skip adding files"
           echo >&2 "-s  skip syncing"
           echo >&2 "-c  repos for which to sync content (not with -s)"
           echo >&2 "-f  force adding file (not with -a)"
           echo >&2 "-w  sync file content only on wifi (not with -s)"
           echo >&2 "-u  fast sync file content (not with -s)"
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

        # Check options
        if [ -n "$INCHARGE" ]; then
            local CHARGE_STATUS="$(cat /sys/class/power_supply/battery/status 2>/dev/null | tr '[:upper:]' '[:lower:]')"
            #local CHARGE_LEVEL="$(dumpsys battery | awk '/level:/ {print $2}')"
            if [ "$CHARGE_STATUS" != "charging" -a "$CHARGE_STATUS" != "full" ]; then
                echo "[warning] Device is not in charge. Disable file addition and file content syncing..."
                unset ANNEX_CONTENT_REMOTE ANNEX_ADD
            fi
        fi
        if [ -n "$WIFI_DEVICE" ] && ! ip addr show dev "$WIFI_DEVICE" 2>/dev/null | grep "state UP" >/dev/null; then
            echo "[warning] Wifi device '$WIFI_DEVICE' is not connected. Disable file content syncing..."
            unset ANNEX_CONTENT_REMOTE
        fi

        # Main script
        echo "[annex] start at $(date)"
        _IFS="$IFS"; IFS=$'\n'
        for REPO in "$BASEDIR" $(cat "$REPOLIST" 2>/dev/null); do
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
            # Add files
            if [ -n "$ANNEX_ADD" ]; then
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
            # Sync files metadata
            if [ -n "$ANNEX_SYNC" ]; then
                if ! git config --get user.name >/dev/null 2>&1; then
                    echo "[annex] Setup local user name and email"
                    ${DBG} git config --local user.name "$USER"
                    ${DBG} git config --local user.email "$USER@$HOSTNAME"
                fi
                echo "[annex] Sync metadata"
                ${DBG} git annex sync
            fi
            # Copy files content
            if [ -n "$ANNEX_CONTENT" ]; then
                for REMOTE in ${ANNEX_CONTENT:-$(git remote)}; do
                    if git ls-remote "$REMOTE" >/dev/null; then
                        echo "[annex] Send files to remote '$REMOTE'"
                        ${DBG} git annex copy . --to "$REMOTE" ${ANNEX_FAST}
                    fi
                done
            fi
        done
        IFS="$_IFS"
        echo "[annex] end at $(date)"
    } 2>&1 | tee "$LOGFILE"
    exit 0
)
