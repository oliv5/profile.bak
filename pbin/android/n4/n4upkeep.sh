#!/system/bin/sh
# crontab rule: 0 4 * * * /sdcard/nosync/profile/pbin/android/n4/n4upkeep.sh
(
  # init
  date
  PATH="/sdcard/nosync/profile/pbin/android:$PATH"

  # mount directories
  mkdir -p /sdcard/abin /sdcard/pbin
  su root -- mount -o bind,rw /sdcard/nosync/profile/pbin /sdcard/pbin
  su root -- mount -o bind,rw /sdcard/nosync/profile/pbin/android /sdcard/abin

  # update repos
  (cd /sdcard/nosync/profile; git fetch; git merge)

  # copy files

  # annex files
  . annex_up.sh -b /sdcard -w wlan0 -c rpi -f -g

  # end
  date
) >/sdcard/n4upkeep.log 2>&1
