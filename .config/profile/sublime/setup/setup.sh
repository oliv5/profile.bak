#!/bin/sh
# http://docs.sublimetext.info/en/latest/getting_started/install.html
tar -xvjf sublime_text_3_build_3083_x64.tar.bz2
#sudo rm -rf /opt/sublime_text_3
#sudo mv -fv sublime_text_3/ /opt/
sudo cp -rv sublime_text_3/ /opt/
sudo rm -rf sublime_text_3/
sudo ln -sfv /opt/sublime_text_3/sublime_text /usr/bin/sublime
sudo sh -c "cat > /usr/share/applications/sublime.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=Sublime Text 3
# Only KDE 4 seems to use GenericName, so we reuse the KDE strings.
# From Ubuntu's language-pack-kde-XX-base packages, version 9.04-20090413.
GenericName=Text Editor

Exec=sublime
Terminal=false
Icon=/opt/sublime_text_3/Icon/48x48/sublime-text.png
Type=Application
Categories=TextEditor;IDE;Development
X-Ayatana-Desktop-Shortcuts=NewWindow

[NewWindow Shortcut Group]
Name=New Window
Exec=sublime -n
TargetEnvironment=Unity
EOF"

