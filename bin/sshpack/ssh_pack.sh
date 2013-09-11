#!/bin/bash
OPTS_7Z="-t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off"
BACKUP_DIR="${SSHPACK_PATH}/.backup"

function ssh-pack() {
  ARCHIVE=${BACKUP_DIR}/sshpack_etc_$(date +%s).7z
  # Check environment
  [ -z "${SSHPACK_PATH}" ] && echo "Variable \$SSHPACK_PATH not defined..." && exit 0
  # Compress
  7z a $OPTS_7Z -mhe=on -p ${ARCHIVE} ${SSHPACK_PATH}/etc
  # Push to FTP server
  _ssh-push ${ARCHIVE}
}

function ssh-unpack() {
  ARCHIVE=${BACKUP_DIR}/sshpack_etc_$(date +%s).7z
  # Check environment
  [ -z "${SSHPACK_PATH}" ] && echo "Variable \$SSHPACK_PATH not defined..." && exit 0
  # Pull from FTP server
  _ssh-pull ${BACKUP_DIR}/sshpack_etc.7z
  mv ${BACKUP_DIR}/sshpack_etc.7z ${ARCHIVE}
  # Deflate
  7z x ${ARCHIVE}
}

function ssh-unpack-legacy() {
  # Check environment
  [ -z "${SSHPACK_PATH}" ] && echo "Variable \$SSHPACK_PATH not defined..." && exit 0
  # Pull from FTP server
  _ssh-pull ${BACKUP_DIR}/sshpack.exe
  # Deflate
  7z x ${BACKUP_DIR}/sshpack.exe
}

function _ssh-push() {
  # Check environment
  [ -z "${SSHPACK_PATH}" ] && echo "Variable \$SSHPACK_PATH not defined..." && exit 0
  # Server
  FTPHOST="ftpperso.free.fr"
  FTPUSER="olivkta"
  FTPPWD="/private/bin"
  # FTP transfer
  ftp -n -i -d <<END_SCRIPT
    lcd ${SSHPACK_PATH}
    open ${FTPHOST}
    user ${FTPUSER}
    cd ${FTPPWD}
    bin
    put $1
    quit
END_SCRIPT
}

function _ssh-pull() {
  # Check environment
  [ -z "${SSHPACK_PATH}" ] && echo "Variable \$SSHPACK_PATH not defined..." && exit 0
  # Server
  HTTPUSER="${3:-oliv5}"
  # Read password
  trap "stty echo" SIGINT
  stty -echo
  read -p "Enter FTP password (user:${HTTPUSER}): " PASSWD
  stty echo
  trap "" SIGINT
  # Download
  wget --user="${HTTPUSER}" --password="${PASSWD}" "$@" http://${FTPHOST}/${FTPPWD}/$(filename $1) -o ${SSHPACK_PATH}/$1
}
