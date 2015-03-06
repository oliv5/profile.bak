# ~/.profile: executed by the command interpreter for login shells.
# Not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Misc variables
[ -z "$USER" ] && export USER="$(id -un)"
[ -z "$HOME" ] && export HOME="$(grep "$USER" /etc/passwd | cut -d: -f6)"
[ -z "$LOGNAME" ] && export LOGNAME="$USER"
[ -z "$HOSTNAME" ] && export HOSTNAME="$(/bin/hostname)"
[ -z "$DOMAIN" ] && export DOMAIN="$(/bin/hostname -d)"
[ -z "$DISPLAY" ] && export DISPLAY=":0"

# Load next script (dash-only)
export ENV="$HOME/.profilerc"

# Set load flag
export ENV_PROFILE=$((ENV_CNT=ENV_CNT+1))

# Load local profile script
if [ -r "$HOME/.profile.local" ]; then
  export ENV_PROFILE_LOCAL=$((ENV_CNT=ENV_CNT+1))
  . "$HOME/.profile.local"
fi
