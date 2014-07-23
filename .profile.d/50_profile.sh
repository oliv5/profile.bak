#!/bin/bash
# Base profile settings

# Prevent Ctrl-D exit session
export IGNOREEOF=1

# Use vim as editor
[ -z "$EDITOR" ] && export EDITOR="$(which vi)"
[ -z "$VISUAL" ] && export VISUAL="$(which vi)"

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
alias bb='cdb;cdb'
alias bbb='cdb;cdb;cdb'
alias f='cdf'
alias ff='cdf;cdf'
alias fff='cdf;cdf;cdf'

# Editor aliases/fcts
alias g='gedit'
alias gv='gvim'
alias e='gvim'
alias sse='ss | cut -c 9- | xargs gvim'
alias gse='gs | grep modified | cut -d : -f 2 | xargs gvim'
function ffe() {
  ff "$@" | xargs gvim
}

# Alias misc
alias hi='history'
alias mo='mimeopen'

