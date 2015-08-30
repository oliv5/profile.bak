#!/system/bin/sh
su root -c "mkdir -p /sdcard/bin; mount -o bind,rw /sdcard/nosync/profile/bin/profile/android /sdcard/bin"
