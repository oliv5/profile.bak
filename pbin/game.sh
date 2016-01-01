#!/bin/sh

# Wine list prefix
wine_list() {
    ls -d "$GAMESROOT/wine/.wine_"*
}

# Wine test prefix
wine_test() {
    local WINEPREFIX="$GAMESROOT/wine/.wine_$GAME"
    [ -d "$WINEPREFIX" ] && 
        echo "Prefix '$GAME' exists." ||
        echo "Prefix '$GAME' does not exist."
}

# Wine setup
wine_setup() {
    local WINEPREFIX="$GAMESROOT/wine/.wine_$GAME"

    # Write/edit launch script
    if [ ! -e "$GAMESCRIPT" ] && ask_question "Create script $GAMESCRIPT? (y/n) " y Y >/dev/null; then
        cat >"$GAMESCRIPT" <<EOF
#!/bin/sh
(   cd "$GAMEDIR"
    SCREEN_RES="$(xrandr --current | grep \* | cut -d' ' -f4)"
    WINEPREFIX="$WINEPREFIX" optirun wine "${GAME}.exe"
    xrandr -s "${SCREEN_RES:-800x600}"
)
EOF
    fi
    if [ -f "$GAMESCRIPT" ] && ask_question "Edit script $GAMESCRIPT? (y/n) " y Y >/dev/null; then
        vi "$GAMESCRIPT"
    fi
    chmod +x "$GAMESCRIPT"

    # Setup wineprefix
    for PACKAGE in d3dx9_36 dxdiag directx9 directx10 mfc42 vcrun6 quartz; do
        if ask_question "Install $PACKAGE? (y/n) " y Y >/dev/null; then
        WINEPREFIX="$WINEPREFIX" optirun winetricks "$PACKAGE"
        fi
    done

    # Call general config tools
    if ask_question "Run winetricks? (y/n) " y Y >/dev/null; then
        WINEPREFIX="$WINEPREFIX" optirun winetricks
    fi
    if ask_question "Run winecfg? (y/n) " y Y >/dev/null; then
        WINEPREFIX="$WINEPREFIX" winecfg
    fi
    if ask_question "Run dxdiag? (y/n) " y Y >/dev/null; then
        WINEPREFIX="$WINEPREFIX" optirun wine dxdiag
    fi
}

# Wine delete prefix
wine_delete() {
    local WINEPREFIX="$GAMESROOT/wine/.wine_$GAME"
    rm -r "$GAMESCRIPT" "$WINEPREFIX"
}

# Dosbox setup
dosbox_setup() {
    local GAMECONF="$GAMESROOT/${GAME}.conf"
    cat >"$GAMESCRIPT" <<EOF
#!/bin/sh
dosbox -userconf -conf ${GAME}.conf
EOF
    chmod +x "$GAMESCRIPT"
    cat >"$GAMECONF" <<EOF
# Main config files are $HOME/.dosbox/*.conf
# Refer to these files for details
[cpu]
core=auto
cputype=auto
cycles=fixed 5000

[autoexec]
keyb fr
mount C "$GAMEDIR"
c:
cd "$GAME"
${GAME}
EOF
}

# Dosbox delete
dosbox_delete() {
    local GAMECONF="$GAMESROOT/${GAME}.conf"
    rm "$GAMESCRIPT" "$GAMECONF"
}

# Run game
run() {
    eval "$GAMESCRIPT" "$@"
}

########################################
########################################
# Main
GAME="${1:?No name for the game...}"
GAMESROOT="$HOME/games"
GAMEDIR="$GAMESROOT/${GAME}"
GAMESCRIPT="$GAMESROOT/${GAME}.sh"
shift
# Last commands in file
# Execute function from command line
[ $# -gt 0 -a ! -z "$1" ] && "$@" || true
