#!/bin/sh
mount /dev/${1:?Please specify the root device} /mnt
mount --bind /dev /mnt/dev
mount --bind /dev/pts /mnt/dev/pts
mount -t sysfs /sys /mnt/sys
mount -t proc /proc /mnt/proc
chroot /mnt
