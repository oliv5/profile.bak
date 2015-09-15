#!/bin/sh
ADB_SDCARD="/storage/sdcard0"
ADB_HOME="$ADB_SDCARD/git-annex.home"
PRIVATE="${PRIVATE:-$HOME}"

# Check requirements
echo "[bootstrap] check fct requirements"
for FCT in grep awk sed cut tr /data/data/ga.androidterm/bin/git; do
    RES=$(adb shell su -c 'command -v '$FCT' >/dev/null || echo '$FCT)
    if [ -n "$RES" ]; then
	echo "[bootstrap] function $FCT is missing. Abort..."
	kill $$
    fi
done

# Setup ssh
echo "[bootstrap] setup ssh"
adb push "$PRIVATE/sshpack/.ssh/annex/id_rsa" "$ADB_HOME/.ssh/"
adb push "$PRIVATE/sshpack/.ssh/config" "$ADB_HOME/.ssh/"

# Upload setup script
echo "[bootstrap] upload setup script"
adb push "$PRIVATE/home/home-nexus4/bin/git.sh" "$ADB_HOME/"
adb push "$PRIVATE/home/home-nexus4/bin/setup.sh" "$ADB_HOME/"

# Run setup script
echo "[bootstrap] run setup script"
adb shell su -c 'export HOME=\"$ADB_HOME\"; . \"$ADB_HOME/setup.sh\" -a'
