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
  for NAME in "$@"; do
    ps -C "$@" -o pid=
  done
}

uid() {
  for NAME in "$@"; do
    ps -C "$@" -o user=
  done
}

# System information
sys-iostat() {
  iostat -x 2
}

sys-stalled() {
  while true; do ps -eo state,pid,cmd | grep "^D"; echo "—-"; sleep 5; done
}

sys-cpu() {
  sar ${1:-1} ${2}
}

cpu-avg() {
  eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$3}; END {print sum}'"
}

mem-avg() {
  eval "ps aux ${1:+| grep $1} | awk 'BEGIN {sum=0} {sum+=\$4}; END {print sum}'"
}

cpu-inst() {
  if [ -z "$1" ]; then
    top -d 0.5 -b -n2 | grep "Cpu(s)" | tail -n 1 | awk '{print $2 + $4 + $6}'
  else
    top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$9}; END {print sum}'
  fi
}

mem-inst() {
  if [ -z "$1" ]; then
    top -d 0.5 -b -n2 | grep "Mem:" | tail -n 1 | awk '{print ($5*100/$3)}'
  else
    top -d 0.5 -b -n2 | grep "$1" | awk 'BEGIN {sum=0} {sum+=$10}; END {print sum}'
  fi
}

swap-inst() {
  top -d 0.5 -b -n2 | grep "Swap:" | tail -n 1 | awk '{print ($5*100/$3)}'
}

cpu-top() {
  eval "ps aux --sort -%cpu ${1:+| head -n $(($1 + 1))}"
}

mem-top() {
  eval "ps aux --sort -rss ${1:+| head -n $(($1 + 1))}"
}

kill-cpu-top() {
  local END=$((${1:-1} + 1))
  ps a --sort -%cpu | awk "NR>1 && NR<=$END {print \$1;}" | xargs kill ${@:2}
}

kill-mem-top() {
  local END=$((${1:-1} + 1))
  ps a --sort -rss | awk "NR>1 && NR<=$END {print \$1;}" | xargs kill ${@:2}
}

mem-ps() {
  while read command percent rss; do
    if [ "${command}" != "COMMAND" ]; then
      rss="$(echo "scale=2;${rss}/1024" | bc)"
    fi
    printf "%-26s%-8s%s\n" "${command}" "${percent}" "${rss}"
  done < <(ps -A --sort -rss -o comm,pmem,rss | head -n 11)
}

# system information aliases
alias cpu='cpu-inst'
alias mem='mem-inst'
alias swap='swap-inst'

################################
# Keyboad layout
alias keyb-list='grep ^[^#] /etc/locale.gen'
alias keyb-set='setxkbmap -layout'
alias keyb-setfr='setxkbmap -layout fr'


################################
# Language selection functions
lang-fr() {
  export LANGUAGE="fr:en"
  export LC_ALL="fr_FR.UTF-8"
}
lang-en() {
  unset LANGUAGE
  export LC_ALL="en_US.UTF-8"
}

################################
# Cmd exist test
cmd-exists() {
  command -v ${1} >/dev/null
}

# Cmd unset
cmd-unset() {
  unalias $* 2>/dev/null
  unset -f $* 2>/dev/null
}

################################
# Chroot
mk-chroot(){
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
make-deb() {
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
