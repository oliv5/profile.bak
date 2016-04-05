#!/bin/sh
# https://github.com/spf13/spf13-vim.git
# http://vim.spf13.com/
set -e

# Backup current installation
if ls -d ./spf13-vim*/ >/dev/null 2>&1; then
	tar --remove-files -cvzf "./spf13-vim.$(date +%Y%m%d-%H%M%S).tgz" ./spf13-vim*/ 2>/dev/null
fi

# Download the setup script and run it
(curl https://j.mp/spf13-vim3 -L | APP_PATH="$PWD/spf13-vim" HOME="$APP_PATH" sh)
