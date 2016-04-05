#!/bin/sh
# See http://vim.spf13.com/
set -e
cd spf13-vim
git pull
vim +BundleInstall! +BundleClean +q
