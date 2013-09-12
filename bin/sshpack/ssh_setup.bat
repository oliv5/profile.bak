@echo off

REM Extract win32 tools here
win32.exe

REM Cleanup
del /s *.log

REM Set path
set PATH=%PATH%;%CD%\utils\

REM Goto home directory
cd ../..
echo %CD%

REM Download .sshpack
echo Update this section to retrieve password
goto :EOF
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Password: " HTTPPASSWD
stty echo; trap "" SIGINT
wget.exe --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack.7z

# Install .sshpack
7z.exe x sshpack.7z

# Delete .sshpack archive
del sshpack.7z
