#!/bin/sh

function sys-iostat() {
	iostat -x 2
}

function sys-stalled() {
	while true; do ps -eo state,pid,cmd | grep "^D"; echo "—-"; sleep 5; done
}
