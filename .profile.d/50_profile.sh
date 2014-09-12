#!/bin/bash
# Base profile settings

# Prevent Ctrl-D exit session
export IGNOREEOF=1

# Start ssh-agent when not already running
pgrep -u $USER ssh-agent >/dev/null || eval $(ssh-agent)

# Use vim as editor
[ -z "$EDITOR" ] && export EDITOR="$(which vim)"
[ -z "$VISUAL" ] && export VISUAL="$(which vim)"

# Pagers
[ -z "$PAGER" ] && export PAGER="less -s"

# History
export HISTSIZE=5000
export HISTFILESIZE=5000
# Avoid duplicates in history
export HISTIGNORE='&:[ ]*'

# Alias ls
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -laF'
alias lsg='ls | grep'

# Alias cd/back
alias b='cdb'
alias f='cdf'

# Editor aliases/fcts
function g() { (command -v geany >/dev/null && geany "$@") || (command -v gedit >/dev/null && gedit "$@"); }
alias e='gvim'
alias sse='ss | cut -c 9- | xargs gvim'
alias gse='gs | grep modified | cut -d : -f 2 | xargs gvim'
function ffe() {
  ff "$@" | xargs gvim
}

# Alias misc
alias hi='history'
alias mo='mimeopen'

