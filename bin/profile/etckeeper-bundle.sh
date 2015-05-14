#!/bin/sh
DIR="/home/olivier/repo/sync/git/bundle"
sudo /usr/bin/git -C /etc bundle create "$DIR/etc.bundle.$(uname -n).$(date +%Y%m%d-%H%M%S).git" --all --tags --remotes
