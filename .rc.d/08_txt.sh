#!/bin/sh

# Insert text at line(s)
# sed -i "${MATCH}i${TEXT}" "$FILE"
txt_insert_at() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '${MATCH}i${TEXT}'"
	done
	eval sed ${INPLACE:+-i} ${SED:--n p} "\"$FILE\""
}
txt_insert_at_all() {
	local TEXT="${1:?No text replacement specified...}"
	local MATCH="${2:?No pattern specified...}"
	shift 2
	for FILE; do
		sed ${INPLACE:+-i} -e "${MATCH}i${TEXT}" "$FILE"
	done
}

# Insert text before matching line(s)
# sed -i -e "/$MATCH/i"$'\\\n'"$TEXT"$'\n' "$FILE"
txt_insert_before() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '/${MATCH}/i${TEXT}'"
	done
	eval sed ${INPLACE:+-i} ${SED:--n p} "\"$FILE\""
}
txt_insert_before_all() {
	local TEXT="${1:?No text replacement specified...}"
	local MATCH="${2:?No pattern specified...}"
	shift 2
	for FILE; do
		sed ${INPLACE:+-i} -e "/${MATCH}/i${TEXT}" "$FILE"
	done
}

# Insert text after matching line(s)
# sed -i -e "/$MATCH/a"$'\\\n'"$TEXT"$'\n' "$FILE"
txt_insert_after() {
	local FILE="${1:?No file specified...}" TEXT="${2:?No text specified...}" SED=""
	shift 2
	for MATCH; do
		SED="${SED:+$SED }-e '/${MATCH}/a${TEXT}'"
	done
	eval sed ${INPLACE:+-i} ${SED:--n p} "\"$FILE\""
}
txt_insert_after_all() {
	local TEXT="${1:?No text replacement specified...}"
	local MATCH="${2:?No pattern specified...}"
	shift 2
	for FILE; do
		sed ${INPLACE:+-i} -e "/${MATCH}/a${TEXT}" "$FILE"
	done
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
	eval sed ${INPLACE:+-i} ${SED:--n p} "\"$FILE\""
}
txt_cut_at_all() {
	local START="${1:?No start position specified...}"
	local END="${2:?No end position specified...}"
	shift 2
	for FILE; do
		sed ${INPLACE:+-i} -n "${START},${END}p" "$FILE"
	done
}

# Cut file before matching line
txt_cut_before() {
	local FILE="${1:?No file specified...}" MATCH="${2:?No pattern specified...}"
	sed ${INPLACE:+-i} "0,/${MATCH}/d" "$FILE"
}
txt_cut_before_all() {
	local MATCH="${1:?No pattern specified...}"
	shift
	for FILE; do
		sed ${INPLACE:+-i} "0,/${MATCH}/d" "$FILE"
	done
}

# Cut file after matching line
txt_cut_after() {
	local FILE="${1:?No file specified...}" MATCH="${2:?No pattern specified...}"
	sed ${INPLACE:+-i} -n "/${MATCH}/q;p" "$FILE"
	#sed ${INPLACE:+-i} "/${MATCH}/,$d" "$FILE"
}
txt_cut_after_all() {
	local MATCH="${1:?No pattern specified...}"
	shift
	for FILE; do
		sed ${INPLACE:+-i} -n "/${MATCH}/q;p" "$FILE"
		#sed ${INPLACE:+-i} "/${MATCH}/,$d" "$FILE"
	done
}

# Get matching line numbers
txt_get_line_num() {
	local FILE="${1:?No file specified...}" MATCH="${2:?No pattern specified...}"
	grep -n -e "$MATCH" "$FILE" | cut -f1 -d:
}
txt_get_line_num_all() {
	local MATCH="${1:?No pattern specified...}"
	shift
	for FILE; do
		grep -n -e "$MATCH" "$FILE" | cut -f1 -d:
	done
}
