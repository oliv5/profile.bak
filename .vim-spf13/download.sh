#!/bin/sh
# https://github.com/spf13/spf13-vim.git
# http://vim.spf13.com/
cd ~/.vim-spf13/
ls ./spf13-vim* >/dev/null 2>&1 && tar -cvzf "./spf13-vim.$(date +%Y%m%d-%H%M%S).tgz" ./spf13-vim* 2>/dev/null
sh <(curl https://j.mp/spf13-vim3 -L) || ./spf13-vim3.sh
