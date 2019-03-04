#!/bin/sh

# Insert text at line(s)
txt_insert_at() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	shift 2
	for LINE; do
		sed -i "${LINE}i${TEXT}" "$FILE"
	done
}

# Insert text before matching line(s)
txt_insert_before() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	shift 2
	for LINE; do
		sed -i -e "/$LINE/i"$'\\\n'"$TEXT"$'\n' "$FILE"
	done
}

# Insert text after matching line(s)
txt_insert_after() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	shift 2
	for LINE; do
		sed -i -e "/$LINE/a"$'\\\n'"$TEXT"$'\n' "$FILE"
	done
}

# Cut file at given lines
txt_cut_at() {
	local FILE="${1:?No file specified...}"
	shift
	while [ $# -gt 1 ]; do
		sed -i -n "${1},${2}p" "$FILE"
		shift 2
	done
}

# Cut file before matching line
txt_cut_before() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	sed -i "0,/${TEXT}/d" "$FILE"
}

# Cut file after matching line
txt_cut_after() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	sed -i -n "/${TEXT}/q;p" "$FILE"
	#sed -i "/${TEXT}/,$d" "$FILE"
}

# Get matching line numbers
txt_get_line_num() {
	local TEXT="${1:?No text specified...}" FILE="${2:?No file specified...}"
	grep -n -e "$TEXT" "$FILE" | cut -f1 -d:
}
