#!/bin/sh
curl https://search.maven.org/remote_content?g=com.madgag&a=bfg&v=LATEST --output ~/bin/bfg.jar && chmod +x ~/bin/bfg.jar
git clone https://github.com/ingydotnet/git-subrepo
cat >> "${PRIVATE:-$HOME}/.rc.local.end" <<EOF

# Load git-subrepo
source /path/to/git-subrepo/.rc

EOF
