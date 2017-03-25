#!/bin/sh

openssl_mkcert() {
    local CERT="${1:-personal}"
    local SIZE="${2:-4096}"
    local DURATION="${3:-11499}"
    local CIPHER="${4:-aes256}"
    local HASH="${4:-sha256}"
    local DHSIZE="${5:-2048}"

    echo "Generating the diffie hellman parameters..."
    [ ! -s "${CERT}.dh" ] && 
	openssl dhparam -out "${CERT}.dh" ${DHSIZE} ||
	echo "Keep existing diffie hellman parameters file."
    echo

    echo "Generating private key..."
    [ ! -s "${CERT}.key" ] && 
	openssl genrsa -${CIPHER} -out "${CERT}.key" ${SIZE} ||
	echo "Keep existing private key file."
    echo

    echo "Generating the request certificate..."
    [ ! -s "${CERT}.csr" ] && 
	openssl req -new -${HASH} -key "${CERT}.key" -out "${CERT}.csr" ||
	echo "Keep existing certificate request file."
    echo

    echo "Generating the certificate..."
    [ ! -s "${CERT}.crt" ] && 
	openssl x509 -req -days ${DURATION} -in "${CERT}.csr" -signkey "${CERT}.key" -out "${CERT}.crt" ||
	echo "Keep existing certificate file."
    
    chmod 600 "${CERT}."*
}

openssl_mkpem() {
    local CERT="${1:-personal}"
    openssl rsa -in "${CERT}.key" -out "${CERT}.tmpkey"
    cat "${CERT}.crt" "${CERT}.tmpkey" "${CERT}.dh" > "${CERT}.pem"
    rm "${CERT}.tmpkey"
    chmod 600 "${CERT}."*
}

openssl_clearkey() {
    local CERT="${1:-personal}"
    openssl rsa -in "${CERT}.key" -out "${CERT}.tmpkey"
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ "${1%%_*}" = "openssl" ] && "$@" || true
