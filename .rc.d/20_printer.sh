#!/bin/sh
# See https://www.cups.org/documentation.php/options.html

# Printer setup
prn_setup() {
  sudo lpadmin -p "${1:?Printer name not specified}" -E -v "${2:?Printer URL not specified}" -P "${3:?PPD file path not specified}"
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
alias prn_default='lpstat -p -d'
alias prn_print='lp'
alias prn_enable='cupsenable'
alias prn_disable='cupsdisable'
alias prn_stat='lpstat'
alias prn_id='lpq'
alias prn_cancel='lprm'
alias prn_move='lpmove'
#alias prn_cancel='cancel'
alias prn_uninstall='lpoptions -x'
