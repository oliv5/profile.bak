#!/system/bin/sh
# Keep a number of mounts matching input regex
SEARCH="${1:?No mount specified...}"
WANTED="${2:-0}"
COUNT="$(mount | grep -e "$SEARCH" | wc -l)"
su root -- <<EOF
  mount | grep -e "$SEARCH" | cut -d ' ' -f 3 | 
    while IFS= read -r MOUNT && [ $COUNT -gt $WANTED ]; do
      COUNT=$((COUNT - 1))
      umount "$MOUNT"
    done
EOF
