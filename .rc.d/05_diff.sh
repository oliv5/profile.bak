#!/bin/sh
DIFF_EXCLUDE="\.git\|\.svn"

# Diff directories
diffd() {
  diff -rq "$@" | grep -ve $DIFF_EXCLUDE
}

# Diff tree
difft() {
  local TEMP="$(mktemp)"
  find "$1" -type d -printf "%P\n" | sort > "$TEMP"
  find "$2" -type d -printf "%P\n" | sort | diff - "$TEMP"
  rm "$TEMP"
}
difftt() {
  local TEMP="$(mktemp)"
  tree -i "$1" > "$TEMP"
  tree -i "$2" | diff - "$TEMP"
  rm "$TEMP"
}

# Count number of lines which differs
diffc() {
  diff -U 0 "$1" "$2" | grep '^+[^+]' | wc -l
}

# Count number of bloc which differs
diffbc() {
  diff -U 0 "$1" "$2" | grep '^@' | wc -l
}

# Util fct to pipe 2 commands into one
_diff_pipe() {
  local R="${1:?Reader command not specified...}"
  local W1="${2:?Writer command 1 not specified...}"
  local W2="${3:?Writer command 2 not specified...}"
  if command -v bash >/dev/null; then
    # Use process substitution
    bash -c "$R <($W1) <($W2)"
  else
    # Manual process substitution
    local P1="$(mktemp -u)"
    mkfifo -m 600 "$P1"
    local P2="$(mktemp -u)"
    mkfifo -m 600 "$P2"
    eval "$W1" > "$P1" &
    eval "$W2" > "$P2" &
    eval "$R" "$P1" "$P2" 
    rm "$P1" "$P2"
  fi
}

# Diff/meld byte-limited portions of the input files with cut -b
diffp() {
  _diff_pipe "diff" "cut -b ${3:-1-} \"$1\"" "cut -b ${3:-1-} \"$2\""
}
diffpm() {
  _diff_pipe "meld" "cut -b ${3:-1-} \"$1\"" "cut -b ${3:-1-} \"$2\""
}

# Diff/meld line-limited portions of the input files with awk
diffl() {
  _diff_pipe "diff" "awk \"NR>=${3:-1}${4:+ && NR<=$4}\" \"$1\"" "awk \"NR>=${3:-1} ${4:+&& NR<=$4}\" \"$2\""
}
difflm() {
  _diff_pipe "meld" "awk \"NR>=${3:-1}${4:+ && NR<=$4}\" \"$1\"" "awk \"NR>=${3:-1} ${4:+&& NR<=$4}\" \"$2\""
}

# Hex-diff 2 input files
diffh() {
  cmp -l "$1" "$2" | gawk '{printf "%08X %02X %02X\n", $1-'${3:-0}', strtonum(0$2), strtonum(0$3)}'
  #_diff_pipe "diff" "hexdump -C \"$1\"" "hexdump -C \"$2\""
}
diffhm() {
  _diff_pipe "meld" "hexdump -C \"$1\"" "hexdump -C \"$2\""
}
diffhr() {
  find "$1" -type f -exec sh -c '
    set -vx
    cmp "$1" "$(echo $1 | sed -e "s;$2;$3;")"
  ' _ "{}" "$1" "$2" \;
}

#######################

# Diff using rsync
diffr() {
  rsync -avsn "$@"
}
diffrd() {
  rsync -avsn --delete "$@" | grep "^delet"
}
diffru() {
  rsync -avsn --existing "$@"
}
diffrn() {
  rsync -avsn --ignore-existing "$@"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#diff}" != "$1" ] && "$@" || true
