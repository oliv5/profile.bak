#!/system/bin/sh
ANNEX_BIN="/data/data/ga.androidterm/runshell"
USER="$(ls -l "$ANNEX_BIN" | awk 'NR>1 {print $3}')"
su "$USER" -c "$ANNEX_BIN"
