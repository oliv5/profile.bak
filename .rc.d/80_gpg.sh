#!/bin/sh

# Aliases
alias gpg_export_pub='gpg --armor --export'
alias gpg_export_priv='gpg --armor --export-secret-key'
gpg_export_all() {
	local WHO="${1:?No recipient specified...}"
	local NAME="${2:?No output file name specified...}"
	gpg --armor --export "$WHO" > "${NAME}.pub.asc"
	gpg --armor --export-secret-keys "$WHO" > "${NAME}.sec.asc"
	gpg --armor --export-secret-subkeys "$WHO" > "${NAME}.sec.sub.asc"
	gpg --armor --gen-revoke "$WHO" > "${NAME}.rev.asc"
}
