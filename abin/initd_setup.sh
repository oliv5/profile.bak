#!/system/bin/sh
# Copy or write init.d scripts
# Run in a subshell because of the exit command
(
  SRC=""
  DST="/data/local/userinit.d"
  NAME="initd.$(date +%Y%m%d-%H%M).sh"
  COMMANDS=""

  # Get arguments
  while getopts "n:f:h" OPTFLAG; do
    case "$OPTFLAG" in
      n) NAME="$(basename "${OPTARG}")";;
      f) SRC="${OPTARG}"; NAME="$(basename "${OPTARG}")";;
      *) echo >&2 "Usage: initd_setup.sh [-h] [-n name] [-f file] -- <commands>"
         echo >&2 "-n  output script name ($NAME by default)"
         echo >&2 "-f  input script path"
         echo >&2 "-h  show this help"
         echo >&2 "<commands> are appended to the output script"
         exit 1
         ;;
    esac
  done
  shift $(($OPTIND - 1))
  unset OPTIND OPTFLAG OPTARG
  COMMANDS="$@"
  
  # Create target directory
  su root -- mkdir -p "$(dirname "$DST")"

  # Check source
  if [ -n "$SRC" ] && [ ! -f "$SRC" ]; then
    echo "[error] file $SRC not found. Abort..."
    exit 2
  fi
  
  # File overwrite
  DST="$(readlink -f "$DST")/$NAME"
  if [ -d "$DST" ]; then
    echo "[error] $DST is a directory: cannot overwrite it. Abort..."
    exit 2
  elif [ -f "$DST" ]; then
    echo "[warning] File $DST exists already. Overwrite? (y/n) " 
    read ANSWER
    if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
      exit 2
    fi
  fi

  # Copy/link existing user script
  if [ -f "$SRC" ]; then
    echo "[initd] copy script $SRC to $DST"
    cp -v "$SRC" "$DST" 
    #echo "[initd] link script $SRC to $DST"
    #ln -svf "$SRC" "$DST"
  elif [ -n "$COMMANDS" ]; then
    # Create new file and write commands
    echo "[initd] write script $DST"
    echo "$COMMANDS" > "$DST"
  fi
)
