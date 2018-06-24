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

# Start gnome keyring daemon
gnome_keyring_agent() {
	command -v gnome-keyring-daemon >/dev/null 2>&1 || return 1
	if pgrep -f 'gnome-keyring-daemon' >/dev/null; then
		GNOME_KEYRING_CONTROL="/run/user/$(id -u)/keyring"
	fi
	eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg 2>/dev/null)"
	export SSH_AUTH_SOCK GNOME_KEYRING_CONTROL
	return 0
}

# Start agents with hardcoded order of priority: gnome keyring > gpg-agent > ssh-agent
start_agent() {
	gnome_keyring_agent || gpg_agent_ssh || ssh_agent || true
}
