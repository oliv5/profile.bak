#!/bin/sh
PROFILE="$HOME/.config/profile"
PREFIX="$HOME/.wine-sourceinsight"
USER_PREFIX="$PREFIX/drive_c/users/$USER"
USER_APP="$HOME/.local/share/applications/wine/Programs/SourceInsight"
EXE="$1"

if ! command -v wine >/dev/null; then
	echo "Wine not found.Abort..."
	return 1
fi

# Init the prefix
WINEPREFIX="$PREFIX" wine cmd /c echo Installing sourceinsight

# Convert user links to directory in the prefix itself
find "$USER_PREFIX" -maxdepth 1 -type l -execdir sh -c 'rm "{}"; mkdir "{}"' \;

# Start the install process
if [ ! -z "$EXE" ]; then
	WINEPREFIX="$PREFIX" wine "$EXE"
fi

# Link the configuration file to the repository
#ln -sf "$PWD/GLOBAL.CF3" "$USER_PREFIX/Mes documents/Source Insight/Settings/GLOBAL.CF3"
find "$USER_PREFIX" -type f -name "GLOBAL.CF3" -exec cp "$PWD/GLOBAL.CF3" "{}" \;

