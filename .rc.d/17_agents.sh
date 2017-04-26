#!/bin/sh

# SSH-agent
ssh_agent() {
	command -v ssh-agent >/dev/null 2>&1 || return 1
	SSH_AGENT_FILE="$HOME/.ssh-agent-info"
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
	GPG_AGENT_FILE="$HOME/.gpg-agent-info"
	export GPG_TTY=$(tty)
	if test -f "$GPG_AGENT_FILE" && \
		kill -0 $(cut -d: -f 2 "$GPG_AGENT_FILE") 2>/dev/null; then
		export GPG_AGENT_INFO=$(cat "$GPG_AGENT_FILE")
	else
		eval $(gpg-agent --daemon "$@") >/dev/null
		echo "$GPG_AGENT_INFO" > "$GPG_AGENT_FILE"
	fi
	return 0
}

# GPG agent with SSH support
gpg_agent_ssh() {
	gpg_agent --enable-ssh-support
}
