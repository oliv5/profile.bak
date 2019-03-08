#!/bin/sh

# Insert text at line(s)
# sed -i "${MATCH}i${TEXT}" "$FILE"
txt_insert_at() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '${MATCH}i${TEXT}'"
	done
	eval sed ${INPLACE:+-i} "$SED" "$FILE"
}

# Insert text before matching line(s)
# sed -i -e "/$MATCH/i"$'\\\n'"$TEXT"$'\n' "$FILE"
txt_insert_before() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '/$MATCH/i$TEXT'"
	done
	eval sed ${INPLACE:+-i} "$SED" "$FILE"
}

# Insert text after matching line(s)
# sed -i -e "/$MATCH/a"$'\\\n'"$TEXT"$'\n' "$FILE"
txt_insert_after() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '/$MATCH/a$TEXT'"
	done
	eval sed ${INPLACE:+-i} "$SED" "$FILE"
}

# Cut file at given lines
# sed -i -n "${1},${2}p" "$FILE"
txt_cut_at() {
	local FILE="${1:?No file specified...}" SED=""
	shift
	while [ $# -gt 1 ]; do
		SED="${SED:+$SED }-n '${1},${2}p'"
		shift 2
	done
	eval sed ${INPLACE:+-i} "$SED" "$FILE"
}

# Cut file before matching line
txt_cut_before() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}"
	sed ${INPLACE:+-i} "0,/${TEXT}/d" "$FILE"
}

# Cut file after matching line
txt_cut_after() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}"
	sed ${INPLACE:+-i} -n "/${TEXT}/q;p" "$FILE"
	#sed ${INPLACE:+-i} "/${TEXT}/,$d" "$FILE"
}

# Get matching line numbers
txt_get_line_num() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}"
	grep -n -e "$TEXT" "$FILE" | cut -f1 -d:
}
