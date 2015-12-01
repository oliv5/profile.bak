#!/bin/sh

################################
# Get sys info
# http://jeffskinnerbox.me/posts/2014/Mar/31/howto-linux-maintenance-and-filesystem-hygiene/
alias kernel_name='uname -sr'
alias kernel_ver='uname -v'
alias dist_name='cat /etc/*-release'
alias dist_ver='lsb_release -a'
alias disk_info='sudo lshw -class disk -class storage -short'
alias disk_drive='hwinfo --disk --short'
alias rpi_fw='/opt/vc/bin/vcgencmd version'

# RPI System update
rpi_update() {
  if ! command -v rpi-update >/dev/null; then
    sudo apt-get install rpi-update
    if [ $? -nq 0 ]; then
      # install tools to upgrade Raspberry Pi's firmware
      sudo wget https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update
      sudo chmod +x /usr/bin/rpi-update
    fi
  fi
  sudo BRANCH=next rpi-update
}

# Smartmontools checks
smart_basicstest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Check the disk's overall health
  sudo smartctl -H "$DEV"
}

smart_shorttest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Short, but more extensive test
  sudo smartctl -t short "$DEV"
}

smart_longtest() {
  local DEV="${1:?No device specified...}"
  # Check SMART support
  sudo smartctl -i "$DEV" || { echo "Device does not support SMARTs"; exit 1; }
  # Turn on some SMART features
  sudo smartctl -s on -o on -S on "$DEV"
  # Long test
  sudo smartctl -t short "$DEV"
  # Check results
  sudo smartctl -l selftest "$DEV"
}

# Filesystem commands
fsck_force(){
  sudo touch /forcefsck
}
fsck_repair() {
  local DEV="${1:?No device specified...}"
  if mountpoint "$DEV" >/dev/null && ! sudo umount "$DEV"; then
    echo "Cannot umount '$DEV'. Abort..."
    return 1
  fi
  sudo fsck -y "$DEV"
}

# Find garbage
tmp_list() {
  ( set -vx
    printf "Home garbage\n"
    find "$HOME" -type f -name "*~" -print
    ls "${HOME}"/.macromedia/* "${HOME}"/.adobe/*
    printf "\nSystem coredumps\n"
    sudo find /var -type f -name "core" -print
    printf "\nTemporary files\n"
    sudo ls /tmp
    sudo ls /var/tmp
    printf "\nLogs\n"
    sudo du -a -b /var/log | sort -n -r | head -n 10
    sudo ls /var/log/*.gz
    printf "\nOpened but deleted\n"
    sudo lsof -nP | grep '(deleted)'
    sudo lsof -nP | awk '/deleted/ { sum+=$8 } END { print sum }'
    sudo lsof -nP | grep '(deleted)' | awk '{ print $2 }' | sort | uniq
  )
}

lsof_close(){
  # For all open but deleted files associated with process 2746, trunctate the file to 0 bytes
  local PID="${1:?No PID specified...}"
  cd /proc/$PID/fd 
  ls -l | grep '(deleted)' | awk '{ print $9 }' | while read FILE; do :> /proc/$PID/fd/$FILE; done
}

# Cleanup packages
pkg_clean() {
  sudo apt-get autoclean
  sudo apt-get clean
  sudo apt-get autoremove
}

# Cleanup old kernels
kernel_ls() {
  dpkg -l 'linux-*'
}
kernel_current() {
  uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/"
}
kernel_others() {
  dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'
}

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
# TTys
alias tty_list='ps aux|grep /usr/bin/[X]'
alias tty_active='cat /sys/class/tty/tty0/active'
alias tty_next='sudo fgconsole'

# Find display
show_display() {
  ps a | awk '/[X]org/ {print $6}'
}

# Env
alias envg='env | grep -i'

################################
# Processes
alias psf='ps -faux'
alias pse='ps -ef'
alias psg='ps -ef | grep -i'
alias psu='ps -fu $USER'
alias pg='pgrep -fl'
alias pgu='pgrep -flu $(id -u $USER)'
alias lsg='ls | grep -i'
alias llg='ll | grep -i'
alias lsofg='lsof | grep -i'

pid() {
  for NAME; do
    ps -C "$@" -o pid=
  done
}

uid() {
  for NAME; do
    ps -C "$@" -o user=
  done
}

################################
# Syslog
alias syslog='sudo tail /var/log/syslog'
alias auth='sudo tail /var/log/auth.log'

# System information
sys_iostat() {
  iostat -x 2
}

sys_stalled() {
  while true; do ps -eo state,pid,cmd | grep "^D"; echo "—-"; sleep 5; done
}

sys_cpu() {
  sar ${1:-1} ${2}
}

################################
# Memory information
mem() { free -mt --si; }
mem_free()   { free | awk 'FNR==2 {print $4}'; }
swap_free()  { free | awk 'FNR==4 {print $4}'; }
mem_used()   { free | awk 'FNR==2 {print $3}'; }
swap_used()  { free | awk 'FNR==4 {print $3}'; }
mem_total()  { free | awk 'FNR==2 {print $2}'; }
swap_total() { free | awk 'FNR==4 {print $2}'; }
mem_free_cache() { free | awk '{if (FNR==2){sum+=$4} else if (FNR==3){sum-=$4}} END {print sum}'; }
mem_used_cache() { free | awk '{if (FNR==2){sum+=$3} else if (FNR==3){sum-=$3}} END {print sum}'; }

################################
# Processes information
alias cpu='cpu_ps'

cpu_ps() {
  # use eval because of the option "|" in $1
  eval ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=$3}; END {print sum}'
}

mem_ps() {
  # use eval because of the option "|" in $1
  eval ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=$4}; END {print sum}'
}

cpu_list() {
  local NUM=$((${1:-1} + 1))
  shift $(min 1 $#)
  # use eval because of the option "|" in $1
  eval ps ${@:-aux} --sort -%cpu ${NUM:+| head -n $NUM}
}

mem_list() {
  local NUM=$((${1:-1} + 1))
  shift $(min 1 $#)
  # use eval because of the option "|" in $1
  eval ps ${@:-aux} --sort -rss ${NUM:+| head -n $NUM}
}

cpu_listshort() {
  cpu_list "$1" ax -o comm,pid,%cpu,cpu
}

mem_listshort() {
  mem_list "$1" ax -o comm,pid,pmem,rss,vsz
}

kill_cpu() {
  local NUM=$((${1:-1} + 1))
  shift $(min 1 $#)
  ps a --sort -%cpu | awk 'NR>1 && NR<=$NUM {print $1;}' | xargs -r kill "$@"
}

kill_mem() {
  local NUM=$((${1:-1} + 1))
  shift $(min 1 $#)
  ps a --sort -rss | awk 'NR>1 && NR<=$NUM {print $1;}' | xargs -r kill "$@"
}

################################
# Zombies processes management
# List zombies
zombie_ls() {
  ps aux | awk '"[Zz]" ~ $8 { print $2; }'
}

# Try to kill zombies by detaching them from their parent
zombie_kill() {
  local _PID _PPID
  ps -e -o pid,ppid,state,comm |
    awk '"[Zz]" ~ $3 { printf("%d %d %s\n", $1, $2, $4); }' |
      while IFS=$' \n' read _PID _PPID _NAME; do
        echo "Kill zombie $_NAME (PID: $_PID PPID: $_PPID)"
        gdb -q -nx -ex "attach $_PPID" -ex "call waitpid($_PID, 0, 0)" -ex "detach"
      done
}

################################
# IPC management
sem_purge() {
  ipcs -s | awk '/0/ {print $2}' | xargs -n 1 ipcrm -s
}

################################
# EINTR retry fct
#http://unix.stackexchange.com/questions/16455/interruption-of-system-calls-when-a-signal-is-caught
eintr() {
  local EINTR=4
  eval "$@"
  while [ $? -eq $EINTR ]; do
    eval "$@"
  done
}

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
# Language selection functions
lang_fr() {
  export LANGUAGE="fr:en"
  export LC_ALL="fr_FR.UTF-8"
}
lang_en() {
  unset LANGUAGE
  export LC_ALL="en_US.UTF-8"
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
  (crontab -l ; echo "$@") | sort - | uniq - | crontab -
}
# Add to system crontab
cron_useradd() {
  sudo sh -c 'echo "$@" >> "/etc/cron.d/$USER"'
}

################################
# http://unix.stackexchange.com/questions/59112/preserve-directory-structure-when-moving-files-using-find
# Move/copy by replicating directory structure
_mkdir_exec() {
  local EXEC="${1:-echo}"
  local SRC="$2"
  local DST="$(path_abs "${3:-.}")"
  shift 3
  local BASENAME="$(basename "$SRC")"
  find "$(dirname "$SRC")" ${BASENAME:+-name "$BASENAME"} $@ -exec sh -c '
      EXEC="$1"
      shift
      for x do
        mkdir -p "$0/${x%/*}" &&
        $EXEC "$x" "$0/$x"
      done
    ' "$DST" "$EXEC" {} +
}
alias mkdir_cp='_mkdir_exec "cp -v"'
alias mkdir_mv='_mkdir_exec "mv -v"'

##############################
# Add ssh dedicated command id in ~/.ssh/authorized_keys
# Use ssh-copy-id for std login shells
ssh_copy_cmd_id() {
  ssh ${1:?No host specified} -p ${2:?No port specified...} -- sh -c "cat 'command=\"${3:?No command specified...},no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${SSH_ORIGINAL_COMMAND#* }\" ${4:?No ssh key specified...}' >> '$HOME/.ssh/authorized_keys'"
}

##############################
# Find duplicate files
alias ff_dup='find_duplicates'
find_duplicates() {
  local TMP1="$(tempfile)"
  local TMP2="$(tempfile)"
  find / -type f -exec md5sum {} \; > "$TMP1"
  awk '{print $1}' "$TMP1" | sort | uniq -d > "$TMP2"
  while read d; do
    echo "---"
    grep $d "$TMP1" | cut -d ' ' -f 2-
  done < "$TMP2"
  rm "$TMP1" "$TMP2" 2>/dev/null
}
