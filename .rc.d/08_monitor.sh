#!/bin/sh

################################
# Get system info
# http://jeffskinnerbox.me/posts/2014/Mar/31/howto-linux-maintenance-and-filesystem-hygiene/
alias kernel_name='uname -sr'
alias kernel_ver='uname -v'
alias dist_name='cat /etc/*-release'
alias dist_ver='lsb_release -a'
alias disk_info='sudo lshw -class disk -class storage -short'
alias disk_drive='hwinfo --disk --short'
alias rpi_fw='/opt/vc/bin/vcgencmd version'

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
ipc_sempurge() {
  ipcs -s | awk '/0/ {print $2}' | xargs -n 1 ipcrm -s
}

ipc_shmpurge() {
  ipcs -m | awk '/0/ {print $2}' | xargs -n 1 ipcrm -m
}
