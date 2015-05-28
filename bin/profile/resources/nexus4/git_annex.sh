#!/system/bin/sh
export PATH="$PATH:/data/data/ga.androidterm/bin"
case "$1" in
    setup)
        chmod 751 /data/data/ga.androidterm/bin
        ;;
    start)
        git annex assistant --foreground
        ;;
    autostart)
        git annex assistant --autostart
        ;;
    status)
        pgrep -l git
        ;;
    stop)
        killall git-annex
        killall git
        ;;
    kill)
        killall -9 git-annex
        killall -9 git
        ;;
    *)
        echo "Missing command or command unknown"
        ;;
esac
