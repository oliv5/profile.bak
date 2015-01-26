#!/bin/bash

# Prevent Ctrl-D exit session
export IGNOREEOF=1

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

# Gvim
alias e='gvim'
alias sse='ss | cut -c 9- | xargs gvim'
alias gse='gs | grep modified | cut -d : -f 2 | xargs gvim'
ffe() {
  ff "$@" | xargs gvim
}

# Gedit/geany
g() {
  eval $(command -v geany || command -v gedit || command -v gvim || false) "$@"
}
alias ssg='ss | cut -c 9- | xargs g'
alias gsg='gs | grep modified | cut -d : -f 2 | xargs g'
ffg() {
  ff "$@" | xargs g
}

# Source insight
alias s='si'

# Alias misc
alias hi='history'
alias mo='mimeopen'
