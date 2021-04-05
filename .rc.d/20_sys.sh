#!/bin/sh

################################
# Forced actions
force_reboot() {
  # https://stackoverflow.com/questions/31157305/forcing-linux-server-node-to-instantly-crash-and-reboot
  # To enable it you probably need to put following in sysctl.conf:
  # kernel.sysrq = 1
  echo 1 > /proc/sys/kernel/sysrq
  echo b > /proc/sysrq-trigger
}

################################
# Set cpu governor
alias cpu_powersave='sudo sh -c "echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"'
alias cpu_performence='sudo sh -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"'
alias cpu_ondemand='sudo sh -c "echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"'

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
# Get XWindow ID
xwmid() {
  xwininfo | awk '/xwininfo: Window id:/ {print $4}'
}
# Get XWindow PID
xwmpid() {
  xprop -id "${1:-$(xwmid)}" | awk '/WM_PID/ {print $3}'
}

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
# Setup user anacron
# https://askubuntu.com/questions/235089/how-can-i-run-anacron-in-user-mode
anacron_usersetup() {
  local DIR="${1:-$HOME}"
  mkdir -p "$DIR/.anacron/etc"
  mkdir -p "$DIR/.anacron/spool"
  [ ! -e "$DIR/.anacron/etc/anacrontab" ] && cat > "$DIR/.anacron/etc/anacrontab" <<EOF
# /etc/anacrontab: configuration file for anacron

# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# period  delay  job-identifier  command
#1         10     testjob         test.sh
EOF
  cron_useradd "@hourly /usr/sbin/anacron -s -t $HOME/.anacron/etc/anacrontab -S $HOME/.anacron/spool"
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

################################
# List kernel modules
alias kernel_lsmod='find /lib/modules/$(uname -r) -type f -name "*.ko*"'
alias kernel_lsmodg='find /lib/modules/$(uname -r) -type f -name "*.ko*" | grep'
kernel_lsmodk() {
  for MOD; do
    grep "$MOD" /lib/modules/$(uname -r)/modules.dep
  done
}

################################
# https://www.cyberciti.biz/tips/linux-security.html
# List accounts with empty passwords
empty_passwd() {
  awk -F: '($2 == "") {print}' /etc/shadow
}

empty_uid() {
  awk -F: '($3 == "0") {print}' /etc/passwd
}

################################
# Bumblebee commands
# https://github.com/Bumblebee-Project/bbswitch
alias bb_status='cat /proc/acpi/bbswitch'
alias bb_on='sudo sh -c "echo ON > /proc/acpi/bbswitch"'
alias bb_off='sudo sh -c "echo OFF > /proc/acpi/bbswitch"'

################################
# nvidia-prime commands
alias primerun='DRI_PRIME=1'

################################
# inotify helpers
alias notify_write='notify close_write'
alias notify_read='notify close_read'
alias notify_rw='notify "close_read,close_write"'
alias notify_create='notify create'
alias notify_mv='notify moved_to'
alias notify='inotify_loop'

# Basic notification method with a loop
# Pros: file move is captured
# Cons: may miss event, high system resource consumption on large directories
inotify_loop() {
  local TRIGGER="${1:?No event to monitor}"
  local FILE="${2:?No dir/file to monitor}"
  shift 2
  local SCRIPT="${@:?No action to execute}"
  sh -c "while true; do inotifywait -qq -e \"$TRIGGER\" \"$FILE\"; eval \"$SCRIPT\"; done" &
}

################################
# List displays
# https://unix.stackexchange.com/questions/17255/is-there-a-command-to-list-all-open-displays-on-a-machine
lsdisplay() {
  # Local display
  (cd /tmp/.X11-unix && for x in X*; do echo ":${x#X}"; done)
  # Remote displays (open TCP ports above 6000)
  netstat -lnt | awk '
  sub(/.*:/,"",$4) && $4 >= 6000 && $4 < 6100 {
    print ($1 == "tcp6" ? "ip6-localhost:" : "localhost:") ($4 - 6000)
  }'
  # Show which program has port 60xx opened
  lsof -i -n | awk '$9 ~ /:60[0-9][0-9]$/ {print}'
}
