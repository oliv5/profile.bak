#!/bin/sh

# Mount ecryptfs
mount-ecryptfs() {
	SRC="${1:?Missing source directory...}"
	DST="${2:?Missing dest directory...}"
	KEY1="${3:?Missing content key...}"
	KEY2="${4:-$KEY1}"
	CIPHER="${5:-aes}"
	KEYLEN="${6:-32}"
	OPT="${@:7}"
	OPT="key=passphrase,ecryptfs_enable_filename_crypto=yes,no_sig_cache=yes,ecryptfs_passthrough=no${OPT:+,$OPT}"
	OPT="ecryptfs_cipher=$CIPHER,ecryptfs_key_bytes=$KEYLEN,ecryptfs_sig=$KEY1,ecryptfs_fnek_sig=$KEY1,ecryptfs_unlink_sigs${OPT:+,$OPT}"
	sudo chmod 500 "$SRC"
	sudo ecryptfs-add-passphrase --fnek
	sudo mount -i -t ecryptfs -o "$OPT" "$SRC" "$DST"
	sudo chmod 700 "$DST"
}

# Mount iso
mount-iso() {
  sudo mount -o loop -t iso9660 "$@"
}

# NFS unmount
alias nfs-umountall='umount -a -t nfs'
nfs-umount() {
	sudo sh -c "
		ifconfig eth0:nfstmp ${2:?NFS IP not specified...} netmask 255.255.255.255
		umount -f -l \"${1:?NFS mount point not specified...}\"
		ifconfig eth0:nfstmp down
	"
}

# NFS remount
nfs-remount() {
	sudo sh -c "
		ifconfig eth0:fakenfs ${2:?NFS IP not specified...} netmask 255.255.255.255
		umount -f -l \"${1:?NFS mount point not specified...}\"
		ifconfig eth0:fakenfs down
		mount \"$1\"
	"
}
