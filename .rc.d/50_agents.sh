#!/bin/sh
# https://www.bootc.net/archives/2013/06/09/my-perfect-gnupg-ssh-agent-setup/

# SSH-agent
ssh_agent() {
	command -v ssh-agent >/dev/null 2>&1 || return 1
	local SSH_AGENT_FILE="$HOME/.ssh-agent-info"
	ssh-add -l >/dev/null 2>&1
	if [ $? -eq 2 ]; then
		test -r "$SSH_AGENT_FILE" && \
			eval "$(cat "$SSH_AGENT_FILE")" >/dev/null
		ssh-add -l >/dev/null 2>&1
		if [ $? -eq 2 ]; then
			(umask 066; ssh-agent > "$SSH_AGENT_FILE")
			eval "$(cat "$SSH_AGENT_FILE")" >/dev/null
		fi
	fi
	return 0
}
ssh_agent_kill() {
	eval $(ssh-agent -k)
}

# Disable SSH-agent forwarding for the local user
# https://developer.github.com/v3/guides/using-ssh-agent-forwarding/
ssh_agent_no_forward() {
	local CFG="$HOME/.ssh/ssh_config"
	if [ ! -e "$CFG" ]; then
		printf "Host *\n    ForwardAgent no\n" > "$CFG"
		chmod 600 "$CFG"
	else
		grep -E "[^#]\s*ForwardAgent no" "$CFG" >/dev/null 2>&1 ||
			sed -i '$ a ForwardAgent no' "$CFG"
	fi
}

# GPG agent (basic)
gpg_agent() {
	command -v gpg-agent >/dev/null 2>&1 || return 1
	local GPG_AGENT_FILE="$HOME/.gpg-agent-info"
	local GPG_AGENT_PID="$(test -f "$GPG_AGENT_FILE" && cut -d: -f 2 "$GPG_AGENT_FILE")"
	export GPG_TTY="$(tty)"
	if [ -n "$GPG_AGENT_PID" ] && [ "$GPG_AGENT_PID" -gt 0 ] && \
		kill -0 "$GPG_AGENT_PID" 2>/dev/null; then
		export GPG_AGENT_INFO="$(cat "$GPG_AGENT_FILE")"
	else
		eval "$(gpg-agent -q -s --daemon "$@" 2>/dev/null)" &&
			{ echo "$GPG_AGENT_INFO" > "$GPG_AGENT_FILE"; } ||
			{ rm "$GPG_AGENT_FILE"; }
	fi
	return 0
}

# GPG agent with SSH support
gpg_agent_ssh() {
	gpg_agent --enable-ssh-support
}

# Reload gpg-agent
gpg_agent_reload() {
	gpg-connect-agent reloadagent /bye
}

# Disable GPG agent
# Set TTL of 0 (see gpg-agent.conf too)
gpg_agent_disable() {
	killall gpg-agent
	gpg-agent --default-cache-ttl 0 -q -s --daemon "$@"
}
gpg_agent_disable_perm() {
	echo "default-cache-ttl-ssh::0" | gpgconf --change-options gpg-agent
	echo "default-cache-ttl::0" | gpgconf --change-options gpg-agent
	echo "max-cache-ttl::0" | gpgconf --change-options gpg-agent
	gpg-connect-agent reloadagent /bye
}

# Start gnome keyring daemon
gnome_keyring_agent() {
	command -v gnome-keyring-daemon >/dev/null 2>&1 || return 1
	eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg 2>/dev/null)"
	export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK GPG_AGENT_INFO
	return 0
}

# Start agents with hardcoded order of priority: gnome keyring > gpg-agent > ssh-agent
start_agent() {
	gnome_keyring_agent || gpg_agent_ssh || ssh_agent || true
}
