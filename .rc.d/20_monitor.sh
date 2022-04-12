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

# Drivers
alias lsmodg='lsmod | grep -i'
alias modinfog='modinfo | grep -i'
alias dmesgg='dmesg | grep -i'

################################
# TTys
alias tty_list='ps aux|grep /usr/bin/[X]'
alias tty_active='cat /sys/class/tty/tty0/active'
alias tty_next='sudo fgconsole'

# Find display
show_display() {
  ps a | grep -E '[X]org' | sed -e 's/^.*\(:[0-9]\+\).*$/\1/g'
}
show_display_local() {
  for x in /tmp/.X11-unix/X*; do echo ":${x##*X}"; done
}
show_display_remote() {
  netstat -lnt | awk '
    sub(/.*:/,"",$4) && $4 >= 6000 && $4 < 6100 {
      print ($1 == "tcp6" ? "ip6-localhost:" : "localhost:") ($4 - 6000)
    }'
}

################################
# Processes

# Grep process IDs
psgp(){
  ps aux | awk "/$1/ "'{print $2}'
}
# User processes
pgu() {
  pgrep -flu "$(id -u ${1:-$USER})"
}
psgu() {
  local USER="${1:-$USER}"
  shift
  psu "$USER" | grep -i "$@"
}
# List of PIDs
pid() {
  # Use xargs to trim leading spaces
  #[ $# -gt 0 ] && ps -C "$@" -o pid= | xargs
  for ARG; do
    { isint "$ARG" && ps -C "$ARG" -o pid= || ps -p "$ARG" -o pid=; } | xargs
  done
}
# List of UIDs
uid() {
  # Use xargs to trim leading spaces
  #[ $# -gt 0 ] && ps -C "$@" -o user= | xargs
  for ARG; do
    { isint "$ARG" && ps -C "$ARG" -o user= || ps -p "$ARG" -o user=; } | xargs
  done
}
# List of PPIDs
ppid() {
  # Use xargs to trim leading spaces
  #[ $# -gt 0 ] && ps -C "$@" -o ppid= | xargs
  for ARG; do
    { isint "$ARG" && ps -C "$ARG" -o ppid= || ps -p "$ARG" -o ppid=; } | xargs
  done
}
ppidn() {
  local PID="${1}"
  local ITER="${2:-0}"
  shift
  for I in $(seq 1 ${ITER}); do
    [ -z "$PID" ] && break
    PID="$(ps -p "$PID" -o ppid=)"
  done
  echo "$PID"
}
# List of zombies
#http://www.noah.org/wiki/Kill_-9_does_not_work
psz() {
  ps aux | awk '"[ZzDd]" ~ $8'
  #ps Haxwwo stat,pid,ppid,user,wchan:25,command | grep -e "^STAT" -e "^D" -e "^Z"
}
# Ps process parent
psp() {
  for ARG; do
    for PID in $(ppid $ARG); do
      ps u -p "$PID"
    done
  done
}

################################
# Wait for process (even not our children)
waitpid(){
  for pid; do
    while kill -0 "$pid" 2>/dev/null; do
      sleep 0.5
    done
  done
}

################################
# Syslog
alias syslog='sudo tail /var/log/syslog'
alias auth='sudo tail /var/log/auth.log'
log() {
  local LOG="${1:?No log specified...}"
  shift
  sudo tail "/var/log/${LOG}" "$@"
}

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
swap_free()  { free | awk 'FNR==3 {print $4}'; }
mem_used()   { free | awk 'FNR==2 {print $3}'; }
swap_used()  { free | awk 'FNR==3 {print $3}'; }
mem_total()  { free | awk 'FNR==2 {print $2}'; }
swap_total() { free | awk 'FNR==3 {print $2}'; }
mem_free_cache() { free | awk '{if (FNR==2){sum+=$4} else if (FNR==3){sum-=$4}} END {print sum}'; }
mem_used_cache() { free | awk '{if (FNR==2){sum+=$3} else if (FNR==3){sum-=$3}} END {print sum}'; }

################################
# Processes information
alias cpu='cpu_ps'

cpu_ps() {
  # use eval because of the option "|" in $1
  eval ps ${2:-aux} ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=$3}; END {print sum}'
}

mem_ps() {
  # use eval because of the option "|" in $1
  eval ps ${2:-aux} ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=$4}; END {print sum}'
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

# http://www.zyxware.com/articles/4446/show-total-memory-usage-by-each-application-in-your-ubuntu-or-any-gnu-linux-system
mem_top() {
  ps -A --sort -rss -o comm,pmem,rss | awk '
  NR == 1 { print; next }
  { a[$1] += $2; b[$1] += $3; }
  END {
    for (i in a) {
      size_in_bytes = b[i] * 1024
      split("B KB MB GB TB PB", unit)
      human_readable = 0
      if (size_in_bytes == 0) {
        human_readable = 0
        j = 0
      }
      else {
        for (j = 5; human_readable < 1; j--)
          human_readable = size_in_bytes / (2^(10*j))
      }
      printf "%-20s\t%s\t%.2f%s\t%s\n", i, a[i], human_readable, unit[j+2], b[i]
    }
  }
' | awk 'NR>1' | sort -rnk4 | awk '
  BEGIN {printf "%-20s\t%%MEM\tSIZE\n", "COMMAND"} 
  {
    printf "%-20s\t%s\t%s\n", $1, $2, $3
  }
' | less
}

################################
# Kill zombie by killing rpciod too
# http://www.noah.org/wiki/Kill_-9_does_not_work
killz(){
  kill -9 "$@"
  ps Haxwwo pid,command | awk '/rpciod/ && !/grep/ {print $1}' | xargs -r kill
}
killza() {
  kill -HUP $(ps -A -ostat,ppid | awk '/[zZ]/ && !a[$2]++ {print $2}')
}

# Kill all zombies by detaching them from their parent
killz_detach() {
  local _PID _PPID
  ps -e -o pid,ppid,state,comm |
    awk '"[Zz]" ~ $3 { printf("%d %d %s\n", $1, $2, $4); }' |
      while IFS=$' \n' read _PID _PPID _NAME; do
        echo "Kill zombie $_NAME (PID: $_PID PPID: $_PPID)"
        gdb -q -nx -ex "attach $_PPID" -ex "call waitpid($_PID, 0, 0)" -ex "detach"
      done
}

################################
# User list - uid can be specified
user_list() {
  getent passwd "$@"
}
# User name - uid can be specified
user_name() {
  getent passwd "$@" | awk -F: '{print $1}'
}

################################
# IPC management
ipc_sempurge() {
  ipcs -s | awk '/0/ {print $2}' | xargs -r -n 1 ipcrm -s
}
ipc_shmpurge() {
  ipcs -m | awk '/0/ {print $2}' | xargs -r -n 1 ipcrm -m
}
ipc_semuser() {
  awk '$5~/[0-9]+/ {print $5}' /proc/sysvipc/sem | sort | uniq | xargs getent passwd | awk -F: '{print $1}'
}
ipc_semstat() {
  echo -e "uid\tnum"
  awk '$5~/[0-9]+/ {print $5}' /proc/sysvipc/sem | sort | uniq -c | sort -r | awk '{print $2 "\t" $1}'
}
ipc_semstatn() {
  #awk '$5~/[0-9]+/ {print $5}' /proc/sysvipc/sem | sort | uniq -c | sort -r | awk '{system("getent passwd " $2 " | cut -d: -f 1"); print $1}'
  awk '$5~/[0-9]+/ {print $5}' /proc/sysvipc/sem | sort | uniq -c | sort -r | awk '{printf $1; "getent passwd " $2 " | cut -d: -f 1" | getline; print " "$1}'
}

################################
lsof_deleted() {
    sudo lsof -nP | grep '(deleted)'
}

lsof_close(){
  # For all open but deleted files associated with process 2746, trunctate the file to 0 bytes
  local PID="${1:?No PID specified...}"
  cd /proc/$PID/fd 
  ls -l | grep '(deleted)' | awk '{ print $9 }' | while read FILE; do :> /proc/$PID/fd/$FILE; done
}

################################
# Find garbage files
ff_garbage() {
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
