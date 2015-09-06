# ~/.profile: executed by the command interpreter for login shells.
# Not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Misc variables
[ -z "$USER" ] && export USER="$(id -un)"
[ -z "$HOME" ] && export HOME="$(grep "$USER" /etc/passwd | cut -d: -f6)"
[ -z "$LOGNAME" ] && export LOGNAME="$USER"
[ -z "$HOSTNAME" ] && export HOSTNAME="$(hostname 2>/dev/null || uname -n)"
[ -z "$DOMAIN" ] && export DOMAIN="$(hostname -d 2>/dev/null)"
[ -z "$DISPLAY" ] && export DISPLAY=":0"

# Set global variables
export ENV_PROFILE=$((ENV_CNT=ENV_CNT+1))
export RC_DIR="${RC_DIR:-$HOME}"
export RC_DIR_LOCAL="${RC_DIR_LOCAL:-$HOME}"

# Load next script (dash-only)
export ENV="$RC_DIR/.rc"

# Load local profile script
if [ -r "$RC_DIR_LOCAL/.profile.local" ]; then
  export ENV_PROFILE_LOCAL=$((ENV_CNT=ENV_CNT+1))
  . "$RC_DIR_LOCAL/.profile.local"
fi

# Exports
export PATH

# make sure this is the last line
# to ensure a good return code
