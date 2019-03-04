#!/bin/sh

# Add gdb breakpoint
gdb_addb() {
	local GDBINIT="${1:-./.gdbinit}"
	touch "$GDBINIT"
	for BREAK; do
		! grep "$BREAK" "$GDBINIT" >/dev/null &&
			txt_insert_line_at "$GDBINIT" "$BREAK" 1
	done
}
