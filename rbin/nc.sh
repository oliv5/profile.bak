#!/bin/sh
# Nextcloud command line operations

# Scan files
nc_scan() {
    local USER="${USER:-www-data}"
    sudo -u "${USER}" php /var/www/nc/occ files:scan "$@"
}

# Maintainance mode on
nc_maintainance_on() {
    local USER="${USER:-www-data}"
    sudo -u "${USER}" php /var/www/nc/occ maintenance:mode --on
}

# Maintainance mode off
nc_maintainance_off() {
    local USER="${USER:-www-data}"
    sudo -u "${USER}" php /var/www/nc/occ maintenance:mode --off
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1#git}" != "$1" ] && "$@" || true
