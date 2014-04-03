#!/bin/bash
# Base profile settings

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"

# Use vim as editor
[ -z "$EDITOR" ] && export EDITOR="$(which vi)"
[ -z "$VISUAL" ] && export VISUAL="$(which vi)"

# Pagers
[ -z "$PAGER" ] && export PAGER="less -s"

# Alias ls
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -laF'

# Alias cd/back
alias b='cdb'
alias bb='cdb;cdb'
alias bbb='cdb;cdb;cdb'

# Editor aliases
alias g='gedit'
alias gv='gvim'
alias e='gvim'
alias es='ss | cut -c 9- | xargs gvim'
alias eg='gs | cut -c 9- | xargs gvim'

# Alias misc
alias hi='history'
alias mo='mimeopen'

