#!/bin/bash
# Base profile settings

# Cleanup path
export PATH="${PATH//\~/${HOME}}"
export PATH="${PATH//.:/}"

# Call env external profile script
if [ -f ~/.localrc ]; then
  source ~/.localrc
fi

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
alias ba='cdb'
alias bb='cdb;cdb'
alias bbb='cdb;cdb;cdb'
alias back='cdb'

# Alias pgrep/pkill
alias pgrep='pgrep -l'
alias psf='ps -faux'
alias psd='ps -def'

# Alias search & open
alias fo='ffo'

# Alias misc
alias g='geany'
alias gv='gvim'
alias hi='history'
alias mo='mimeopen'
