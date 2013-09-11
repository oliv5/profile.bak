#!/bin/bash
#
# Filename: gpg.sh
# Initial date: 2012/11/31
# Licence: GNU GPL
# Dependency: gpg
# optional: zenity, wipe
# Author: Olivier Lanneluc <oliv5@caramail.com>

# Variables
VERSION=0.94
PASSPHRASE=""
SELECTED_RECIPIENT=""
##DEFAULT_RECIPIENT=""
NB_ENCRYPT=0
NB_DECRYPT=0

# Options
EN_ENCRYPT=1
EN_DECRYPT=1
DELETE=1
ZENITY=1
SIMULATE=""
VERBOSE="false"
STDOUT="/dev/null"

# Get command line options
while getopts edksvz OPTNAME
do case "$OPTNAME" in
  e)  EN_DECRYPT="";;
  d)  EN_ENCRYPT="";;
  k)  DELETE=""; echo "Keeping input files." >"$STDOUT";;
  s)  SIMULATE="true"; echo "Performing a dry-run with no file changed." >"$STDOUT";;
  v)  VERBOSE=""; STDOUT="/dev/stdout";;
  z)  ZENITY="";;
  [?]) echo >&2 "Usage: $(basename $0) v$VERSION [-e] [-d] [-k] [-s] [-v] [-z]  ... directories/files"
       echo >&2 "-e    encrypt only"
       echo >&2 "-d    decrypt only"
       echo >&2 "-k    keep input files"
       echo >&2 "-s    simulate"
       echo >&2 "-v    verbose"
       echo >&2 "-z    no zenity"
       exit 1;;
  esac
done
shift $(expr $OPTIND - 1)

# Display a piece of information
DisplayInfo () {
  if [ -z "$ZENITY" ]; then
    echo -e "$1"
    echo -e "$2"
  else
    zenity --info --title "$1" --text "$2"
  fi
}

# Display a warning
DisplayWarning () {
  if [ -z "$ZENITY" ]; then
    echo -e "$1"
    echo -e "$2"
  else
    zenity --warning --title "$1" --text "$2"
  fi
}

# Display a question
DisplayQuestion () {
  if [ -z "$ZENITY" ]; then
    IFS="$(printf '\n')"
    read -s -p "$2 " ANSWER
    echo $ANSWER
  else
    echo $(zenity --title "$1" --entry --hide-text --text="$2" | sed 's/^[ \t]*//;s/[ \t]*$//')
  fi
}

# Display a list of choices, get selection
DisplayList () {
  if [ -z "$ZENITY" ]; then
    IFS="$(printf '\n')"
    echo -e "$1" >/dev/stderr
    echo -e "${@:5}" >/dev/stderr
    read -p "$2 " ANSWER
    echo $ANSWER
  else
    echo $(echo ${*:5} | xargs zenity --title "$1" --text "$2" --list --radiolist --column "$3" --column "$4")
  fi
}

# Loop through nautilus files or command line filess
for SRC in "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$@}"
do
  IFS="$(printf '\n\t')"
  CTRLCHARS="$(printf '*[\001-\037\177]*')"
  for FILE in $(find $SRC -type f ! -name "$CTRLCHARS")
  do
    # Check extension
    EXT=$(echo "$FILE" | grep [.]gpg$)
    if [ "$EXT" != "" -a ! -z "$EN_DECRYPT" ]; then
      echo Decrypting file \"$FILE\" >"$STDOUT" 2>&1

      # Collect GnuPG passphrase
      if [ -z "$PASSPHRASE" ]; then
        ###PASSPHRASE=$(zenity --title "GnuPG Decryption" --entry --hide-text --text="Enter your GnuPG passphrase" | sed 's/^[ \t]*//;s/[ \t]*$//')
        PASSPHRASE=$(DisplayQuestion "GnuPG Decryption" "Enter your key GnuPG passphrase:")
        echo
        if [ -z "$PASSPHRASE" ]; then
          ###$VERBOSE zenity --warning --title "No passphrase" --text "Decryption is disabled!"
          $VERBOSE DisplayWarning "No passphrase" "Decryption is disabled!"
          EN_DECRYPT=""
          continue
        fi
      fi

      # Decrypt
      echo $PASSPHRASE | $SIMULATE gpg -v --batch --passphrase-fd 0 -o ${FILE%.*} -d "$FILE" >"$STDOUT" 2>&1

      # One more file!
      if [ -f "${FILE%.*}" ]; then
        NB_DECRYPT=$(($NB_DECRYPT+1))
      fi

      # Delete original file if new one is present
      if [ ! -z "$DELETE" -a -f "${FILE%.*}" ]; then
        $VERBOSE echo "Wipe input file '$FILE'"
        [ $(stat -c %s "$FILE") -lt 25000000 ] && $SIMULATE wipe -q -f "$FILE" >"$STDOUT" 2>&1 || $SIMULATE rm "$FILE" >"$STDOUT" 2>&1
      fi

    elif [ "$EXT" == "" -a ! -z "$EN_ENCRYPT" ]; then
      echo Encrypting file \"$FILE\" >"$STDOUT" 2>&1

      if [ -z "$SELECTED_RECIPIENT" ]; then
        # List the available keys
        KEY_NAMES=$(gpg --list-keys | egrep '^uid' | awk '{$1=$1;print}' | cut -d '(' -f1 | cut -d '<' -f1 | sed -e 's/uid //g;s/^[ \t]*//;s/[ \t]*$//;s/ /_/g')
        ##DEFAULT_RECIPIENT=$(echo "$KEY_NAMES" | head -n 1 | sed -e 's/_/ /g' | sed 's/^[ \t]*//;s/[ \t]*$//')
        KEYS=""
        for KEY in $KEY_NAMES; do
          KEYS="KEY ${KEY} ${KEYS}"
        done

        # Select the key
        ###SELECTED_RECIPIENT=$(echo $KEYS | xargs zenity --title "Encryption Keys" --text "Select the key to be used for encryption" --list --radiolist --column "" --column "Available keys on your keyring:")
        SELECTED_RECIPIENT=$(DisplayList "Encryption Keys" "Select the encryption key:" "" "Available keys:" "$KEYS")
        if [ -z "$SELECTED_RECIPIENT" ]; then
          ###$VERBOSE zenity --warning --title "No key" --text "Encryption is disabled!"
          $VERBOSE DisplayWarning "No key" "Encryption is disabled!"
          EN_ENCRYPT=""
          continue
        fi
        SELECTED_RECIPIENT=$(echo "$SELECTED_RECIPIENT" | sed -e 's/_/ /g' | sed 's/^[ \t]*//;s/[ \t]*$//')
      fi

      # Encrypt
      ##gpg -v --batch --default-recipient "$SELECTED_RECIPIENT" --hidden-encrypt-to "$DEFAULT_RECIPIENT" -e "$FILE" >"$STDOUT" 2>&1
      $SIMULATE gpg -v --batch --no-default-recipient --hidden-recipient "$SELECTED_RECIPIENT" --trust-model always -e "$FILE" >"$STDOUT" 2>&1

      # One more file!
      if [ -f "${FILE}.gpg" ]; then
        NB_ENCRYPT=$(($NB_ENCRYPT+1))
      fi

      # Delete original file if new one is present
      if [ ! -z "$DELETE" -a -f "${FILE}.gpg" ]; then
        $VERBOSE echo "Wipe input file '$FILE'"
        [ $(stat -c %s "$FILE") -lt 25000000 ] && $SIMULATE wipe -q -f "$FILE" >"$STDOUT" 2>&1 || $SIMULATE rm "$FILE" >"$STDOUT" 2>&1
      fi

    else
      echo Skip file \"$FILE\" >"$STDOUT" 2>&1
    fi
  done
done

###$VERBOSE zenity --info --title "Job complete" --text "Encrypted files: $NB_ENCRYPT\nDecrypted files: $NB_DECRYPT"
$VERBOSE DisplayInfo "Job complete!" "Encrypted files: $NB_ENCRYPT\nDecrypted files: $NB_DECRYPT"
