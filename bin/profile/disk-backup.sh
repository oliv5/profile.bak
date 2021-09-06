#!/bin/sh
set -e # exit upon failure
title="db"
src="${1:?No source device specified...}"
dst="${2:?No destination device specified...}"
options=""
norun=""
skip=""
shift 2

# End function
end() {
	# Untrap (first instruction of the trap or double trap is possible)
	trap - KILL INT EXIT
	# Disable error check
	set +e
	# Wait for child process
	wait; sleep 1 # for rsync children
	# Umount both disks
	echo "[$title] Umount devices"
	sudo umount -l "$mount1" "$mount2"
	# Delete mount points
	echo "[$title] Remove mountpoints"
	rmdir "$mount1" "$mount2" "$tmpdir" 2>/dev/null
	echo "[$title] Done at $(date)"
}

# Start
echo "[$title] Start at $(date)"

# Create temp mountpoints
echo "[$title] Make mountpoints"
tmpdir="$(mktemp -d)"
mount1="$tmpdir/src"
mount2="$tmpdir/dst"
mkdir "$mount1" "$mount2"

# Error trap
trap "end" KILL INT EXIT

# Mount both disks
echo "[$title] Mount devices"
sudo mount -v "$src" "$mount1"
sudo mount -v "$dst" "$mount2"

# Read rsync options in source directory
if [ -f "$mount1/.${title}.options" ]; then
	options="$(cat "$mount1/.${title}.options")"
	echo "[$title] Rsync options: $options"
fi

# Look for the norun flag in source directory
if [ -f "$mount1/.${title}.norun" ]; then
	echo "[$title] Norun flag is ON"
	norun=1
fi

# Check source for the delete flag
if [ -f "$mount1/.${title}.delete" ]; then
	echo "[$title] Delete flag is ON"
	options="$options --delete-before"
fi

# Check source for the dryrun flag
if [ -f "$mount1/.${title}.dryrun" ]; then
	echo "[$title] Dryrun flag is ON"
	options="$options --dry-run"
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
		if [ -d "$mount1/$dir" ] && ([ -z "$skip" ] || ! grep "$dir/" "$mount1/.${title}.skip"); then
			echo "[$title] Process $mount1/$dir"
			rsync -av "$options" -- "$mount1/$dir/" "$mount2/$dir/"
		else
			echo "[$title] Skip missing directory $mount1/$dir ..."
		fi
	done
fi

# End
end
