#!/bin/sh
install.sh none none
if ls -d ./spf13-vim*/ >/dev/null 2>&1; then
	tar --remove-files -cvzf "./spf13-vim.$(date +%Y%m%d-%H%M%S).tgz" ./spf13-vim*/ 2>/dev/null
fi
