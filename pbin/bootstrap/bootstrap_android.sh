#!/bin/sh
SDCARD="/storage/sdcard0"
PRIVATE="${PRIVATE:-$HOME}"
ADB_PRIVATE="$SDCARD/private"
ADB_HOME="$SDCARD/git-annex.home"
ADB_GIT="/data/data/ga.androidterm/bin/git"
REPO_URL="$(awk '/checkout = .*clone.*home-nexus4.git/{print $4}' "$PRIVATE/sshpack/.mr/private")"

# Test commands
fct_exists() {
    adb shell ${2:+PATH=$PATH:$2 }which "$1" >/dev/null
}

# Check requirements
echo "[bootstrap] check requirements"
for FCT in grep awk sed cut tr "/data/data/ga.androidterm/bin git"; do
    if ! fct_exists $FCT; then
	echo "[bootstrap] function '$FCT' is missing.Cannot go on..."
	kill $$
    fi
done

# Setup ssh
echo "[bootstrap] setup ssh"
adb push "$PRIVATE/sshpack/.ssh/annex/id_rsa" "$ADB_HOME/.ssh/"
adb push "$PRIVATE/sshpack/.ssh/config" "$ADB_HOME/.ssh/"

# Setup home
echo "[bootstrap] setup home"
adb shell "
    mkdir -p '$ADB_PRIVATE'
    cd '$ADB_PRIVATE'
    su -c '
	HOME=\"$ADB_HOME\"
	if [ -d \"$ADB_PRIVATE/home\" ]; then
	    cd \"$ADB_PRIVATE/home\"
	    $ADB_GIT fetch --all
	    for REMOTE in \$($ADB_GIT remote); do
		$ADB_GIT merge \$REMOTE/master
	    done
	else
	    $ADB_GIT clone \"$REPO_URL\" \"$ADB_PRIVATE/home\"
	fi
    '
"

# Run setup script
echo "[bootstrap] run setup script"
adb shell "
    su -c '
	export HOME=\"$ADB_HOME\"
	cd \"$ADB_PRIVATE\"
	. \"$ADB_PRIVATE/home/bin/n4setup.sh\" -a
    '
"
