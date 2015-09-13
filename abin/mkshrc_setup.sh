#!/system/bin/sh
# Setup user mkshrc script
su root -- <<EOF
  MARKER="# load user .mkshrc"
  SDCARD="/storage/sdcard0"
  MKSHRC="/system/etc/mkshrc"
  
  # Check prerequisites
  if [ ! -r "$MKSHRC" ]; then
    echo '[mkshrc] file "$MKSHRC" not found. Cannot setup user .mkshrc'
    exit 1
  fi
  if grep "$MARKER" "$MKSHRC" >/dev/null 2>&1; then
    echo '[mkshrc] user .mkshrc already installed.'
    exit 2
  fi
  
  # Mount /system rw
  mount -o remount,rw /system
  
  # Write file content
  echo "" >>  "$MKSHRC"
  echo "$MARKER" >>  "$MKSHRC"
  echo '. $SDCARD/.mkshrc' >> "$MKSHRC"
  
  # Mount /system ro
  mount -o remount,ro /system
EOF
