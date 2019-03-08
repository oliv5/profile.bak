#!/bin/sh

# Insert in .gdbinit
gdb_add() {
	local GDBINIT=".gdbinit"
	local CMD="${@:?No cmd specified...}"
	touch "$GDBINIT"
	! grep "$CMD" "$GDBINIT" >/dev/null &&
		txt_insert_at "$CMD" "$GDBINIT" 1
}

# Remove from .gdbinit
gdb_rm() {
	local GDBINIT=".gdbinit"
	local CMD="${@:?No cmd specified...}"
	sed -i -n "/$CMD/d" "$GDBINIT"
}

# Aliases
alias 'gdbd=gdb_rm'
alias 'gdbb=gdb_add break'
alias 'gdbw=gdb_add watch'
alias 'gdbtb=gdb_add tbreak'
alias 'gdbtw=gdb_add twatch'
