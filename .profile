# ~/.profile: executed by the command interpreter for login shells.
# Not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# Exit when already loaded
[ -n "$ENV_PROFILE" ] && return

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Misc variables
[ -z "$USER" ] && export USER="$(id -un)"
[ -z "$HOME" ] && export HOME="$(grep "$USER" /etc/passwd | cut -d: -f6)"
[ -z "$LOGNAME" ] && export LOGNAME="$USER"
[ -z "$HOSTNAME" ] && export HOSTNAME="$(/bin/hostname)"
[ -z "$DOMAIN" ] && export DOMAIN="$(/bin/hostname -d)"
[ -z "$DISPLAY" ] && export DISPLAY=":0.0"

# Set load flag
export ENV_CNT=$(expr ${ENV_CNT:-0} + 1)
export ENV_PROFILE=$ENV_CNT
