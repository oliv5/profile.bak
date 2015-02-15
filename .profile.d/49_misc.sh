#!/bin/sh

################################
# Use vim as editor
[ -z "$EDITOR" ] && export EDITOR="$(which vim)"
[ -z "$VISUAL" ] && export VISUAL="$(which vim)"

# Pagers
[ -z "$PAGER" ] && export PAGER="less -s"

################################
# Language selection functions
lang-fr() {
  export LANGUAGE="fr:en"
  export LC_ALL="fr_FR.UTF-8"
}
lang-en() {
  unset LANGUAGE
  export LC_ALL="en_US.UTF-8"
}

################################
# Cmd exist test
cmd-exists() {
  command -v ${1} >/dev/null
}

# Cmd unset
cmd-unset() {
  unalias $* 2>/dev/null
  unset -f $* 2>/dev/null
}

# Remove some aliases/fct shortcuts
cmd-unset which grep find

################################
# Start ssh-agent when not already running
pgrep -u $USER ssh-agent >/dev/null || eval $(ssh-agent)

################################
# Reload ~/.inputrc
bind -f ~/.inputrc

################################
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
