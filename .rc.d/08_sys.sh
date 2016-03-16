#!/bin/sh

################################
# Sudo
if command -v sudo >/dev/null 2>&1; then
  # Sudo now supports alias expansion
  # http://www.shellperson.net/using-sudo-with-an-alias/
  alias sudo='sudo '
else 
  alias sudo='su root --'
fi

################################
# Event tester
alias event_list='xev'
alias event_showkey='showkey -s'

################################
# Keyboad layout
alias keyb_list='grep ^[^#] /etc/locale.gen'
alias keyb_set='setxkbmap -layout'
alias keyb_setfr='setxkbmap -layout fr'

################################
# Chroot
mkchroot(){
  local SRC="/dev/${1:?Please specify the root device}"
  local DST="${2:-/mnt}"
  mount "$SRC" "$DST"
  mount --bind "/dev" "$DST/dev"
  mount --bind "/dev/pts" "$DST/dev/pts"
  mount -t sysfs "/sys" "$DST/sys"
  mount -t proc "/proc" "$DST/proc"
  chroot "$DST"
}

################################
# Fstab to autofs conversion
fstab2autofs() {
  awk 'NF && substr($1,0,1)!="#" {print $2 "\t-fstype="$3 "," $4 "\t" $1}' "$@"
}

################################
# Add to user crontab, ensure uniqness
cron_useradd() {
  (crontab -l; echo "$@") | sort - | uniq - | crontab -
}
# Add to system crontab
cron_sysadd() {
  sudo sh -c 'echo "$@" >> "/etc/cron.d/$USER"'
}

################################
# Rename current logged on user and its group
user_rename_current_user() {
  local OLDNAME="${1:?Old name not specified...}"
  local NEWNAME="${2:?New name not specified...}"
  local DESCR="${3:-$NEWNAME}"
  local CURNAME="$(whoami)"
  echo "List of commands to carry on:"
  echo
  cat <<EOF
exit
ssh $CURNAME@$HOSTNAME "sudo useradd tempuser; sudo passwd tempuser; sudo usermod -a -G sudo tempuser"
ssh tempuser@$HOSTNAME "/bin/sh -c '$(type user_rename | tail -n +2); user_rename $OLDNAME $NEWNAME $DESCR'"
ssh $CURNAME@$HOSTNAME "sudo userdel tempuser"
EOF
}

# Rename another user and its group
user_rename() {
  local OLDNAME="${1:?Old name not specified...}"
  local NEWNAME="${2:?New name not specified...}"
  local DESCR="${3:-$NEWNAME}"
  local CURNAME="$(whoami)"
  if [ "$CURNAME" = "$OLDNAME" ]; then
    echo "Cannot rename the current logged on user."
    user_rename_current_user "$@"
    return 1
  else
    sudo killall -u "$OLDNAME"
    sudo id "$OLDNAME"
    sudo usermod -l "$NEWNAME" "$OLDNAME"
    sudo groupmod -n "$NEWNAME" "$OLDNAME"
    sudo usermod -d /home/"$NEWNAME" -m "$NEWNAME"
    sudo usermod -c "$DESCR" "$NEWNAME"
    sudo id "$NEWNAME"
    return 0
  fi
}
