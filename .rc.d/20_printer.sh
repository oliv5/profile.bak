#!/bin/sh
# See https://www.cups.org/documentation.php/options.html
# See https://docs.oracle.com/cd/E23824_01/html/821-1451/gllgm.html
# Install PPD files in /usr/share/ppd/ -> /etc/cups/ppd

# Printer setup
prn_setup() {
  sudo lpadmin -p "${1:?Printer name not specified}" -E -v "${2:?Printer URL not specified}" -P "${3:?PPD file path not specified}"
}
prn_delete() {
  local NAME="${1:?Printer name not specified}"
  sudo lpoptions -x "$NAME"
  sudo lpadmin -x "$NAME"
}

# Printer options
prn_options() {
  local NAME="${1:?Printer name not specified}"
  local OPTS=""
  shift
  for VALUES; do
    OPTS="$OPTS $VALUES"
  done
  sudo lpoptions -p "$NAME" $OPTS
}

# Aliases
alias prn_default='lpoptions -d -p'
alias prn_print='lp'
alias prn_enable='cupsenable'
alias prn_disable='cupsdisable'
alias prn_stat='lpstat'
alias prn_id='lpq'
alias prn_move='lpmove'
alias prn_cancel='cancel'
#alias prn_cancel='lprm'
