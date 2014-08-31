#!/bin/bash
pushd "$( dirname "${BASH_SOURCE[0]}" )"
mv -v ~/.spf13-vim-3 /tmp/.spf13-vim-3.bak
sh <(curl https://j.mp/spf13-vim3 -L) || ./spf13-vim3.sh
popd
