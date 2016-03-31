#!/bin/sh
set -e # exit upon failure
title="disk-backup"
src="${1:?No source device specified...}"
dst="${2:?No destination device specified...}"
delete=""
norun=""
skip=""
shift 2

# Start
echo "[$title] Start at $(date)"

# Create temp mountpoints
echo "[$title] Make mountpoints"
mount1="$(mktemp -d)"
mount2="$(mktemp -d)"

# Error trap
trap "echo '[$title] Error cleanup...'; 
	sudo umount '$mount1' '$mount2' 2>/dev/null; 
	rm -r -- '$mount1' '$mount2' 2>/dev/null" EXIT

# Mount both disks
echo "[$title] Mount devices"
sudo mount "$src" "$mount1"
sudo mount "$dst" "$mount2"

# Check source for the delete flag
if [ -f "$mount1/.${title}.delete" ]; then
	echo "[$title] Delete flag is ON"
	delete=1
fi

# Check source for the norun flag
if [ -f "$mount1/.${title}.norun" ]; then
	echo "[$title] Skip flag is ON"
	norun=1
fi

# Check source for the skip flag
if [ -f "$mount1/.${title}.skip" ]; then
	echo "[$title] Skip flag is ON"
	skip=1
fi

# Main
if [ -z "$norun" ]; then
	# For each directory
	for dir; do
		if [ -d "$mount1/$dir" ] && ([ -z "$skip" ] || grep "$mount1/$dir" "$mount1/.${title}.skip"); then
			echo "[$title] Process $mount1/$dir"
			(set -vx; rsync -av ${delete:+--delete} -- "$mount1" "$mount2")
		else
			echo "[$title] Skip missing directory $mount1/$dir ..."
		fi
	done
fi

# Umount both disks
echo "[$title] Umount devices"
sudo umount "$mount1"
sudo umount "$mount2"

# Delete mount points
echo "[$title] Remove mountpoints"
rmdir "$mount1"
rmdir "$mount2"

# Untrap
trap - EXIT

# The end
echo "[$title] Done at $(date)"
