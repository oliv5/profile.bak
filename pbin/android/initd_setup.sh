#!/system/bin/sh
# Copy or write init.d scripts
SRC=""
DST="/system/etc/init.d"
NAME="initd.$(date +%Y%m%d-%H%M)"
COMMANDS=""
# Run in a subshell because of the exit command
(
    # Get arguments
    while getopts "n:f:h" OPTFLAG; do
      case "$OPTFLAG" in
        n) NAME="$(basename "${OPTARG}")";;
        f) SRC="${OPTARG}";;
        *) echo >&2 "Usage: initd_setup.sh [-h] [-n name] [-f file] -- <commands>"
           echo >&2 "-n  output script name ($NAME by default)"
           echo >&2 "-f  input script path"
           echo >&2 "-h  show this help"
           echo >&2 "<commands> are appended to the output script"
           exit 1
           ;;
      esac
    done
    unset OPTIND OPTFLAG OPTARG
    
    # Set few variables
    COMMANDS="$@"
    DST="$DST/$NAME"
    
    # Check source
    if [ -n "$SRC" ] && [ ! -f "$SRC" ]; then
      echo "[error] file $SRC not found. Abort..."
      exit 2
    fi
    
    # File overwrite
    if [ -d "$DST" ]; then
      echo "[error] $DST is a directory: cannot overwrite it. Abort..."
      exit 2
    elif [ -f "$DST" ]; then
      read -p "[warning] File $DST exists already. Overwrite? (y/n) " ANSWER
      if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
        exit 2
      fi
    fi

    # Main root script
    su root -- <<EOF
      # Mount /system rw
      mount -o remount,rw /system
      
      # Copy existing user script
      [ -f "$SRC" ] && {
        echo "[initd] copy script $SRC to $DST"
        cp -v "$SRC" "$DST"
      }
      
      # Append additional commands to user initd script
      [ -n "$COMMANDS" ] && {
        echo "[initd] write script $DST"
        echo "$COMMANDS" >> "$DST"
      }

      # Mount /system ro
      mount -o remount,ro /system
EOF
)
