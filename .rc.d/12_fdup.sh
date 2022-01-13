#!/bin/sh

###########################################
# Find duplicate files in directory
# Does not handle filenames with \n inside
alias ff_dup='find_duplicates'
find_duplicates() {
  local TMP1="$(mktemp)"
  local TMP2="$(mktemp)"
  for DIR in "${@:-.}"; do
    find "${DIR:-.}" \( -type f -o -type l \) -exec md5sum "{}" \; | sed -e 's/^\\//' >> "$TMP1"
  done
  #awk '{print $1}' "$TMP1" | sort | uniq -d > "$TMP2"
  sort -k 1 "$TMP1" | cut -d' ' -f 1 | uniq -d > "$TMP2"
  while read SUM; do
    grep "^$SUM" "$TMP1" | cut -d' ' -f 2- | sort
    echo
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}

# Remove duplicated files
# Does not handle filenames with \n inside
# Dry-run only, does not execute the rm command
alias rm_dup='rm_duplicates'
rm_duplicates() {
  find_duplicates "$@" | sed '1d ; /^$/{N;d}' | xargs -r -i -- echo "rm -I -- '{}'"
}

# Find duplicate files in directory
find_duplicates0() {
  local TMP1="$(mktemp)"
  local TMP2="$(mktemp)"
  for DIR in "${@:-.}"; do
    find "${DIR:-.}" \( -type f -o -type l \) -exec md5sum -z "{}" \; >> "$TMP1"
  done
  sort -z -k 1 "$TMP1" | cut -z -d' ' -f 1 | uniq -z -d | xargs -0 -n1 > "$TMP2"
  while read SUM; do
    printf "$SUM\0"
    grep -zZ "$SUM" "$TMP1" | sed -z -e "s/$SUM\s*//"
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}

# Remove duplicated files
# Does not handle filenames with \n inside
# Dry-run only, does not execute the rm command
alias rm_dup0='rm_duplicates0'
rm_duplicates0() {
  find_duplicates0 "$@" | xargs -r0 sh -c '
    while [ $# -gt 0 ]; do
      F="$1"; shift
      if [ ! -e "$F" ] && [ ${#F} -eq 32 ]; then
        shift # Skip next file
      elif [ -e "$F" ]; then
        printf "$F\0"
      fi
    done
  ' _ | xargs -r0 -- echo rm -I --
}

# Find duplicate links of all links (good/bad)
ffl_dup() {
  for D in "${@:-.}"; do
    find "$D" -type l -exec sh -c '
	    find "$2" -lname "*$(basename "$(readlink -q "$1")")" -print0 | sort -z | xargs -r0 -- sh -c "[ \$# -ge 1 ] && echo \$0 \$@"
    ' _ {} "$D" \; | sort -u
  done
}
# Find duplicate links (raw list)
ffl_dupr() {
  for D in "${@:-.}"; do
    find "$D" -type l -exec sh -c '
	    find "$2" -lname "*$(basename "$(readlink -q "$1")")" -print0 | sort -z | xargs -r0 -- sh -c "[ \$# -ge 1 ] && echo \$0 && for F; do echo "\$F"; done"
    ' _ {} "$D" \; | sort -u
  done
}

# Find duplicate links of good links
ffl_dupg() {
  for D in "${@:-.}"; do
    find "$D" -type f -exec sh -c '
	    #find -L "$2" -samefile "$1" -xtype l -print0 | xargs -r0 -- echo
      find "$2" -lname "$(basename "$1")" -print0 | xargs -r0 -- echo
    ' _ {} "$D" \;
  done
}
