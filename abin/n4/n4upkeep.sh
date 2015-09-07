#!/system/bin/sh
# crontab rule: 0 4 * * * /sdcard/nosync/profile/pbin/android/n4/n4upkeep.sh
SDCARD="${1:-/storage/sdcard0}"
# Run in a subshell because of exits
(
  # init
  date
  PATH="/data/data/ga.androidterm/bin:/$SDCARD/nosync/profile/pbin/android:$PATH"
  HOME="$SDCARD/git-annex.home"

  # mount directories
  mkdir -p /sdcard/abin /sdcard/pbin
  su root -- >/dev/null <<EOF
mount -o bind,rw "$SDCARD/nosync/profile/pbin" /sdcard/pbin
mount -o bind,rw "$SDCARD/nosync/profile/pbin/android" /sdcard/abin
EOF

  # update repos
  (cd /sdcard/nosync/profile; git fetch; git merge)

  # remove old backups
  ( cd /sdcard
    git annex numcopies 1
    find /sdcard/backup/mybackup -type d -name 'AppsMedia_*' | 
      sort -r | tail -n -1 | 
      xargs git annex drop
  )

  # annex files
  . annex_up.sh -b /sdcard -w wlan0 -c rpi -f -g

  # end
  date
) 2>&1 | tee "/$SDCARD/n4upkeep.log"
