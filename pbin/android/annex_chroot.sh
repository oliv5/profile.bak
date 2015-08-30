#!/system/bin/sh
export SDCARD="/sdcard"
export ROOT="$SDCARD/git-annex.home"
export PATH="/usr/bin:/sbin:/bin"
export HOME="$ROOT"

my_mount() {
  mkdir -p "$2"; mount -o bind "/$1" "$2"
}

my_umount() {
  umount "$1" ; rmdir "$1"
}

#mount -o remount,exec,dev,suid "$SDCARD"
for f in dev dev/pts proc sys system data; do my_mount "$f" "$ROOT/$f"; done
my_mount "/sdcard/git-annex.home" "$ROOT/sdcard/git-annex.home"
chroot "$ROOT"
my_umount "$ROOT/sdcard/git-annex.home"
for f in dev dev/pts proc sys system data; do my_umount "$ROOT/$f"; done
#mount -o remount,noexec,nodev,nosuid "$SDCARD"
