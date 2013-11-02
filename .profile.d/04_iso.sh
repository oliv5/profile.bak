#!/bin/sh

# Mount iso
function mountiso() {
  mount -o loop -t iso9660 "$@"
}
