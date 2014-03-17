#!/bin/sh

# Mount iso
function mount.iso() {
  sudo mount -o loop -t iso9660 "$@"
}
