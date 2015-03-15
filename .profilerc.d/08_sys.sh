#!/bin/sh

################################
# Syslog
alias syslog='sudo tail /var/log/syslog'

# Processes
alias psf='ps -faux'
alias psd='ps -ef'
alias psg='ps -ef | grep -i'
alias psu='ps -fu $USER'
alias pg='pgrep -fl'
alias pgu='pgrep -flu $(id -u $USER)'

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

cpu_avg() {
  eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$3}; END {print sum}'"
}

mem_avg() {
  eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$4}; END {print sum}'"
}

cpu_inst() {
  if [ -z "$1" ]; then
    top -d 0.5 -b -n2 | grep "Cpu(s)" | tail -n 1 | awk '{print $2 + $4 + $6}'
  else
    top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$9}; END {print sum}'
  fi
}

mem_inst() {
  if [ -z "$1" ]; then
    top -d 0.5 -b -n2 | grep "Mem:" | tail -n 1 | awk '{print ($5*100/$3)}'
  else
    top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$10}; END {print sum}'
  fi
}

swap_inst() {
  top -d 0.5 -b -n2 | grep "Swap:" | tail -n 1 | awk '{print ($5*100/$3)}'
}

cpu_top() {
  eval "ps aux --sort -%cpu ${1:+| head -n $(($1 + 1))}"
}

mem_top() {
  eval "ps aux --sort -rss ${1:+| head -n $(($1 + 1))}"
}

kill_cpu_top() {
  local END=$((${1:-1} + 1))
  shift
  ps a --sort -%cpu | awk 'NR>1 && NR<=$END {print $1;}' | xargs -r kill "$@"
}

kill_mem_top() {
  local END=$((${1:-1} + 1))
  shift
  ps a --sort -rss | awk 'NR>1 && NR<=$END {print $1;}' | xargs -r kill "$@"
}

mem_ps() {
  ps -A --sort -rss -o comm,pmem,rss | head -n 11 |
  while read command percent rss; do
    if [ "${command}" != "COMMAND" ]; then
      rss="$(echo "scale=2;${rss}/1024" | bc)"
    fi
    printf "%-26s%-8s%s\n" "${command}" "${percent}" "${rss}"
  done
  # The following is a bashism
  #done < <(ps -A --sort -rss -o comm,pmem,rss | head -n 11)
}

# system information aliases
alias cpu='cpu_inst'
alias mem='mem_inst'
alias swap='swap_inst'

################################
# Keyboad layout
alias keyb-list='grep ^[^#] /etc/locale.gen'
alias keyb-set='setxkbmap -layout'
alias keyb-setfr='setxkbmap -layout fr'


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
# Cmd exist test
cmd_exists() {
  command -v ${1} >/dev/null
}

# Cmd unset
cmd_unset() {
  unalias $* 2>/dev/null
  unset -f $* 2>/dev/null
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
# Make deb package from source
mkdeb() {
  local ARCHIVE="${1:?No input archive specified}"
  tar zxf "$ARCHIVE" || return 0
  cd "${ARCHIVE%.*}"
  ./configure || return 0
  dh_make -s -f "../$ARCHIVE"
  fakeroot debian/rules binary
}

################################
# Fstab to autofs conversion
fstab2autofs() {
  awk 'NF && substr($1,0,1)!="#" {print $2 "\t-fstype="$3 "," $4 "\t" $1}' "$@"
}
