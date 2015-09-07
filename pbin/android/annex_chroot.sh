#!/system/bin/sh
export SDCARD="/storage/sdcard0"
export ROOT="$SDCARD/git-annex.home"
export PATH="/usr/bin:/sbin:/bin"
export HOME="$ROOT"

chroot_mount() {
  mkdir -p "$2"; mount -o bind "/$1" "$2"
}

chroot_umount() {
  umount "$1" ; rmdir "$1"
}

for f in dev dev/pts proc sys system data; do chroot_mount "$f" "$ROOT/$f"; done
chroot "$ROOT"
for f in dev dev/pts proc sys system data; do chroot_umount "$ROOT/$f"; done
