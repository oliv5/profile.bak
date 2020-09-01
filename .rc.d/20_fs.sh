#!/bin/sh

################################
# Smartmontools HD checks
smart_basicstest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Check the disk's overall health
  sudo smartctl -H "$DEV"
}

smart_shorttest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Short, but more extensive test
  sudo smartctl -t short "$DEV"
}

smart_longtest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Long test
  sudo smartctl -t short "$DEV"
  # Check results
  sudo smartctl -l selftest "$DEV"
}

################################
# Filesystem commands
fsck_force(){
  sudo touch /forcefsck
}
fsck_repair() {
  local DEV="${1:?No device specified...}"
  if mountpoint "$DEV" >/dev/null && ! sudo umount "$DEV"; then
    echo "Cannot umount '$DEV'. Abort..."
    return 1
  fi
  sudo fsck -y "$DEV"
}

################################
# dd utils
dd_status() {
  kill -10 $(pgrep '^dd$')
}
# Local to remote dd
dd_ssh_to_remote() {
  local DEV="${1:?No device specified...}"
  local OUT="${2:?No local output file specified...}"
  shift 2
  sudo dd if="$DEV" | gzip -1 - | pv | ssh "${@:?No ssh remote specified...}" dd of="$OUT.gz"
}
# Remote to local dd
dd_ssh_to_local() {
  local DEV="${1:?No device specified...}"
  local OUT="${2:?No local output file specified...}"
  shift 2
  echo -n "Enter password: "
  ssh -t "${@:?No ssh remote specified...}" "sudo --prompt='' dd if=\"$DEV\" | gzip -f1 -" | dd of="$OUT.gz"
}

################################
# Make iso from block device
mk_rawiso() {
  dd if="${1:-/dev/cdrom}" of="${2:-./myimage.iso}" conv=noerror,notrunc
}

# Make iso from filesystem
mk_isofs() {
  mkisofs -r -l -V "${3:-$(basename "${1%%/}")}" -o "${2:-./myimage.iso}" "${1:?No input directory specified...}"
}

# Make iso from ddrescue & mkisofs
mk_iso() {
  local SRC="${1:?No device specified...}"
  local DST="${2:-./image.iso}"
  local TEMP="${DST%%.iso}.tmp.iso"
  ddrescue -d -r${3:-3} "$SRC" "$TEMP" "${TEMP%%.iso}.map" && {
    sudo mount -t iso9660 "$TEMP" /mnt
    mk_isofs /mnt "$DST" "$(basename "${DST%%.iso}")"
    # && rm "$TEMP" "${TEMP%%.iso}.map"
    sudo umount /mnt
  }
}

# Diff iso versus source
diff_iso() {
  local SRC="${1:?No iso specified...}"
  local REF="${2:?No filesystem to check against...}"
  local MOUNT="${3:-/mnt}"
  mount_iso "$SRC" "$MOUNT"
  diff -rq "$MOUNT" "$REF"
  local RES=$?
  sudo umount "$MOUNT"
  return $RES
}

# Check iso file read
check_iso() {
  local SRC="${1:?No iso specified...}"
  local MOUNT="${2:-/mnt}"
  mount_iso "$SRC" "$MOUNT"
  find "$MOUNT" -type f -print0 | xargs -0 -n1 -I{} cat "{}" > /dev/null
  local RES=$?
  sudo umount "$MOUNT"
  return $RES
}
check_alliso() {
  local MOUNT="${MOUNT:-/mnt}"
  local FAILED=""
  sudo true
  for SRC; do
    echo -n "Check '$SRC' ... "
    if check_iso "$SRC" "$MOUNT" 2>/dev/null; then
      echo "success."
    else
      echo "FAILURE."
    fi
  done
}

################################
# Cue to iso
cue2iso() {
  for F; do
    bchunk "${F%%.cue}.bin" "$F" "${F%%.cue}.iso"
  done
}
# CD burner toc to iso
toc2iso() {
  for F; do
    toc2cue "$F" "${F%%.toc}.cue" &&
    bchunk "${F}.bin" "${F%%.toc}.cue" "${F%%.toc}.iso" &&
    rm "${F%%.toc}.cue"
  done
}
