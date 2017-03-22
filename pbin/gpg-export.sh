#!/bin/sh
WHO="${1:?No recipient specified...}"
NAME="${2:-$(basename "$PWD")}"

gpg --armor --export "$WHO" > "${NAME}.pub.asc"
gpg --armor --export-secret-keys "$WHO" > "${NAME}.sec.asc"
gpg --armor --export-secret-subkeys "$WHO" > "${NAME}.sec.sub.asc"
gpg --armor --gen-revoke "$WHO" > "${NAME}.rev.asc"
