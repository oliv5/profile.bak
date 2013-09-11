#!/bin/bash
. ssh_config.sh ""

# Init
DBG=""
VERSION="$1"
L_SRC="${SSHPACK_PATH}"
L_DST=$(readlink -f "${SSHPACK_PATH}/..")
### NOTE: remote directories must end with a "/" or "\"
R_DST="${SSHPACK_PACK_DST}"
R_DST_SFTP="${SSHPACK_PACK_DST_SFTP}"
R_DST_EXTRACT="${SSHPACK_PACK_EXTRACT}"
L_7ZIP="7z"
L_7ZOPT="\-t7z \-mx=9 \-mmt \-mhe \-r"
R_7ZIP="${SSHPACK_7Z}"
R_7ZOPT="${SSHPACK_7Z_OPT}"
ARCHIVE="sshpack"
##ARCPASSWD="ARCPASSWD"
##ARCPASSWD2="_"
##FTPPASSWD="FTPPASSWD"
##FTPPASSWD2="_"
FTPHOST="ftpperso.free.fr"
FTPUSER="olivkta"
FTPPWD="/private/bin"

# Check destination
if [ -z "${R_DST}" ]; then
  echo No destination defined for this host...
  exit 1
fi

# Version
echo "List of backups"
echo ${L_DST}/${ARCHIVE}_* | xargs -n1 basename
while [ -z "${VERSION}" -o -e "${L_DST}/${VERSION}" ]; do
  read -p "Version number: " VERSION
  VERSION="${ARCHIVE}_v${VERSION}"
  [ -e ${L_DST}/${VERSION} ] && echo "Version \"${VERSION}\" exists already. Please specify another version number."
done

# Verify
echo Backup version ${VERSION}
echo Press enter... && read

# Disable TTY echo
##trap "stty echo; trap - SIGINT" SIGINT
##stty -echo

# Get archive password
##while [ "${ARCPASSWD}" != "${ARCPASSWD2}" ]; do
##  read -p "Archive password: " ARCPASSWD && echo
##  read -p "Re-type password: " ARCPASSWD2 && echo
##done

# Get FTP password
##while [ "${FTPPASSWD}" != "${FTPPASSWD2}" ]; do
##  read -p "FTP password: " FTPPASSWD && echo
##  read -p "Re-type password: " FTPPASSWD2 && echo
##done

# Restore TTY echo
##stty echo
##trap - SIGINT

# Identify pack version
${DBG} rm "${L_SRC}/*.ver" 2>/dev/null
echo ${VERSION} > "${L_SRC}/${ARCHIVE}.ver"
date >> "${L_SRC}/${ARCHIVE}.ver"
##echo Sshpack version ${VERSION} > "${L_SRC}/${VERSION}.ver"
##date >> "${L_SRC}/${VERSION}.ver"

# Make a localcopy of the new pack
##${DBG} cp -R "${L_SRC}" "${L_DST}/${VERSION}"
##echo Press enter... && read

# Compress
${DBG} ${L_7ZIP} a "${L_DST}/${VERSION}.7z" "${L_SRC}"
echo Press enter... && read
${DBG} ${L_7ZIP} a "${L_DST}/${VERSION}.exe" -sfx -p "${L_SRC}"
echo Press enter... && read

# FTP transfer
${DBG} ftp -n -i -d <<END_SCRIPT
  lcd
  open ${FTPHOST}
  user ${FTPUSER}
  bin
  cd ${FTPPWD}
  mdelete ${ARCHIVE}_*.ver
  put ${L_SRC}/${ARCHIVE}.ver
  ##put ${L_SRC}/${VERSION}.ver
  put ${L_DST}/${VERSION}.exe
  rename ${VERSION}.exe ${ARCHIVE}.exe
  quit
END_SCRIPT
echo Press enter... && read

# SFTP transfer
if [ ! -z "${R_DST_SFTP}" ]; then
  ${DBG} ssh_plink.sh ${SSHPACK_ROOT} "mkdir \"${R_DST}\" 2>${SSHPACK_NULL}"
  ${DBG} ssh_sftp.sh ${SSHPACK_ROOT} <<END_SCRIPT
    cd %R_DST_SFTP%
    put ${L_DST}\${VERSION}.7z
    bye
END_SCRIPT
  echo Press enter... && read
fi

# Extract to the sshpack destination
if [ ! -z "${R_DST_EXTRACT}" ]; then
  ${DBG} ssh_plink.sh ${SSHPACK_ROOT} "${R_7ZIP} ${R_7ZIP_OPT} a" "${R_DST_EXTRACT}${ARCHIVE}_prev.7z" ${L_7ZOPT} "${R_DST_EXTRACT}"
  ${DBG} ssh_plink.sh ${SSHPACK_ROOT} "${R_7ZIP} ${R_7ZIP_OPT} x" -y -o "${R_DST_EXTRACT}" "${R_DST}${VERSION}.7z"
  echo Press enter... && read
fi

echo End of script $0
