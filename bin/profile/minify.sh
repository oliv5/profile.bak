#!/bin/sh
# https://github.com/precious/bash_minifier

minify_generate() {
    local SRC DST
    for SRC in "${@:-*.sh}"; do
	DST="${SRC%.*}.min"
	#~ rm "$DST" 2>/dev/null
	test -f "$SRC" || continue
	test -e "$DST" && continue
	( set -e
	    unalias -a
	    python2.7 "$(which minifier.py)" "$SRC" > "$DST"
	    test -x "$SRC" && chmod +x "$DST"
	    bash -n "$DST"
	    bash "$DST"
	)
    done
}

minify_test() {
    (unalias -a; for F in "${@:-*.min}"; do sh $F; done)
}

########################################
########################################
# Execute function from command line
if [ "$1" = "test" ]; then shift; minify_test "$@"; else minify_generate "$@"; fi
