#!/usr/bin/env bash

# Based on https://git-annex.branchable.com/tips/Decrypting_files_in_special_remotes_without_git-annex/
# https://gist.github.com/yibe/edb505a973999fe9aaa6c039c5ed0fbe

usage() {
    echo "Usage: $0 -r REMOTE [-k SYMLINK] [-d FILE...]"
    echo ""
    echo "    Either lookups up key on REMOTE for annex file linked with SYMLINK"
    echo "    or decrypts FILE encrypted for REMOTE."
    echo ""
    echo "    -r: REMOTE is special remote to use"
    echo "    -k: SYMLINK is symlink in annex to print encrypted special remote key for"
    echo "    -d: FILE is path to special remote file(s) to decrypt to STDOUT"
    echo ""
    echo "NOTES: "
    echo "    * Run in an indirect git annex repo."
    echo "    * Must specify -k or -d."
    echo "    * -k prints the key including the leading directory names used for a "
    echo "       directory remote (even if REMOTE is not a directory remote)"
    echo "    * -d works on a locally accessible file. It does not fetch a remote file"
    echo "    * Must have gpg and openssl"
}

decrypt_cipher() {
    cipher="$1"
    echo "$(echo -n "$cipher" | base64 -d | gpg --decrypt --quiet)"
}

encrypt_key() {
    local key="$1"
    local cipher="$2"
    local mac="$3"
    local enckey="GPG$mac--$(echo -n "$key" | openssl dgst -${mac#HMAC} -hmac "$cipher" | sed 's/(stdin)= //')"
    local checksum="$(echo -n $enckey | md5sum)"
    echo "${checksum:0:3}/${checksum:3:3}/$enckey"
}

lookup_key() {
    local encryption="$1"
    local cipher="$2"
    local mac="$3"
    local remote_uuid="$4"
    local symlink="$5"

    if [ "$encryption" == "hybrid" ] || [ "$encryption" == "pubkey" ]; then
        cipher="$(decrypt_cipher "$cipher")"
    fi

    # Pull out MAC cipher from beginning of cipher
    if [ "$encryption" = "hybrid" ] ; then
        cipher="$(echo -n "$cipher" | head  -c 256 )"
    elif [ "$encryption" = "shared" ] ; then
        cipher="$(echo -n "$cipher" | base64 -d | tr -d '\n' | head  -c 256 )"
    elif [ "$encryption" = "pubkey" ] ; then
        # pubkey cipher includes a trailing newline which was stripped in
        # decrypt_cipher process substitution step above
        IFS= read -rd '' cipher < <( printf "$cipher\n" )
    elif [ "$encryption" = "sharedpubkey" ] ; then
        # Full cipher is base64 decoded. Add a trailing \n lost by the shell somewhere
        cipher="$(echo -n "$cipher" | base64 -d)
"
    fi

    local annex_key="$(basename "$(readlink "$symlink")")"
    local checksum="$(echo -n "$annex_key" | md5sum)"
    local branchdir="${checksum:0:3}/${checksum:3:3}"
    if [[ "$(git config annex.tune.branchhash1)" = true ]]; then
        branchdir="${branchdir%%/*}"
    fi
    local chunklog="$(git show "git-annex:$branchdir/$annex_key.log.cnk" 2>/dev/null | grep $remote_uuid: | grep -v ' 0$')"
    local chunklog_lc="$(echo "$chunklog" | wc -l)"
    local chunksize numchunks chunk_key line n

    if [[ -z $chunklog ]]; then
        echo "# non-chunked" >&2
        encrypt_key "$annex_key" "$cipher" "$mac"
    elif [ "$chunklog_lc" -ge 1 ]; then
        if [ "$chunklog_lc" -ge 2 ]; then
            echo "INFO: the remote seems to have multiple sets of chunks" >&2
        fi
        while read -r line; do
            chunksize="$(echo -n "${line#*:}" | cut -d ' ' -f 1)"
            numchunks="$(echo -n "${line#*:}" | cut -d ' ' -f 2)"
            echo "# $numchunks chunks of $chunksize bytes" >&2
            for n in $(seq 1 $numchunks); do
                chunk_key="${annex_key/--/-S$chunksize-C$n--}"
                encrypt_key "$chunk_key" "$cipher" "$mac"
            done
        done <<<"$chunklog"
    fi
}

decrypt_file() {
    local encryption="$1"
    local cipher="$2"
    local file_path="$3"

    if [ "$encryption" = "pubkey" ] ; then
        gpg --quiet --decrypt "${file_path}"
    else
        if [ "$encryption" = "hybrid" ] ; then
            cipher="$(decrypt_cipher "$cipher" | tail -c +257)"
        elif [ "$encryption" = "shared" ] ; then
            cipher="$(echo -n "$cipher" | base64 -d | tr -d '\n' | tail  -c +257 )"
        fi
        gpg --quiet --batch --passphrase "$cipher" --output - "${file_path}"
    fi
}

decrypt_files() {
    local encryption="$1"
    local cipher="$2"
    local file_path
    shift 2
    for file_path in "$@"; do
        decrypt_file "$encryption" "$cipher" "$file_path"
    done
}

main() {
    OPTIND=1

    mode=""
    remote=""

    while getopts "r:k:d" opt; do
        case "$opt" in
            r)  remote="$OPTARG"
                ;;
            k)  if [ -z "$mode" ] ; then
                    mode="lookup key"
                else
                    usage
                    exit 2
                fi
                symlink="$OPTARG"
                ;;
            d)  if [ -z "$mode" ] ; then
                    mode="decrypt file"
                else
                    usage
                    exit 2
                fi
                ;;
        esac
    done

    if [ -z "$mode" ] || [ -z "$remote" ] ; then
        usage
        exit 2
    fi

    shift $((OPTIND-1))

    # Pull out config for desired remote name
    remote_config="$(git show git-annex:remote.log | grep 'name='"$remote ")"

    # Get encryption type and cipher from config
    encryption="$(echo "$remote_config" | grep -oP 'encryption\=.*? ' | tr -d ' \n' | sed 's/encryption=//')"
    cipher="$(echo "$remote_config" | grep -oP 'cipher\=.*? ' | tr -d ' \n' | sed 's/cipher=//')"
    mac="$(echo "$remote_config" | grep -oP 'mac\=.*? ' | tr -d ' \n' | sed 's/mac=//')"
    [ -z "$mac" ] && mac=HMACSHA1
    remote_uuid="$(echo "$remote_config" | cut -d ' ' -f 1)"

    if [ "$mode" = "lookup key" ] ; then
        lookup_key "$encryption" "$cipher" "$mac" "$remote_uuid" "$symlink"
    elif [ "$mode" = "decrypt file" ] ; then
        decrypt_files "$encryption" "$cipher" "$@"
    fi
}

main "$@"
