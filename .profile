# ~/.profile: executed by the command interpreter for login shells.
# Not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Execute system wide profile
#~ if [ -f /etc/profile ]; then
  #~ . /etc/profile
#~ fi

# Misc variables
[ -z "$USER" ] && export USER="$({ id -un 2>/dev/null || id -u; } | awk '{print $1; exit}')"
[ -z "$HOME" ] && export HOME="$(awk -F: '/'$USER'/ {print $6; exit}' /etc/passwd || echo "/home/$USER")"
[ -z "$LOGNAME" ] && export LOGNAME="$USER"
[ -z "$HOSTNAME" ] && export HOSTNAME="$({ hostname 2>/dev/null || uname -n; } | head -n 1)"
[ -z "$DOMAIN" ] && export DOMAIN="$(hostname -d 2>/dev/null | head -n 1)"
[ -z "$DISPLAY" ] && export DISPLAY=":0"

# Set global variables
export ENV_PROFILE=$((ENV_PROFILE+1))
export RC_DIR="${RC_DIR:-$HOME}"
export RC_DIR_LOCAL="${RC_DIR_LOCAL:-$HOME}"

# Declare user script (posix shells only)
export ENV="$RC_DIR/.dashrc"

# Load local profile script
if [ -r "$RC_DIR_LOCAL/.profile.local" ]; then
  export ENV_PROFILE_LOCAL=$((ENV_PROFILE_LOCAL+1))
  . "$RC_DIR_LOCAL/.profile.local"
fi

# Exports
export PATH

# make sure this is the last line
# to ensure a good return code
