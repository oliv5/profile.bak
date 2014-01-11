#!/bin/bash
pushd ../spf13-vim
git pull
vim +BundleInstall! +BundleClean +q
popd
