@echo off

REM Cleanup
del /s *.log

REM Set path
set PATH=%PATH%;%CD%\utils\

REM Download .sshpack
echo Update this section to retrieve password
goto :EOF
read -p "User: " HTTPUSER
trap "stty echo" SIGINT; stty -echo
read -p "Password: " HTTPPASSWD
stty echo; trap "" SIGINT
wget.exe --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack/sshpack.7z
wget.exe --user="${HTTPUSER}" --password="${HTTPPASSWD}" "$@" http://olivkta.free.fr/private/bin/sshpack/sshpack.exe

# Install sshpack
7z.exe x sshpack.7z
sshpack.exe

# Delete sshpack archives
del sshpack.7z
del sshpack.exe
