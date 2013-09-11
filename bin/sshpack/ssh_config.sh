#!/bin/sh
SSH_CONFIG_FILE="${SSHPACK_PATH}/etc/sshpack/sshpack.conf"

# Load configuration
function _ssh-printconfig() {
  # Execute perl script to convert and print the configuration file
  perl -wn -e '
    #!/bin/perl
    $/ = "\r\n";
    chomp;

    #  s{
    #    (?:^|\G)     # start of the last match, so you never backtrack.
    #    (?!\@REM)    # a section without @REM
    #    (.*?)        # followed by anything
    #    %([^\s]+)%   # with %% variable
    #  }
    #  {$1\${$2}}xmg;

    # Skip the string with @REM in it, cut the string in half variable/value
    if (m/(?!\@REM)(.*?=)(.*)/)
    {
      # Get var name & value
      my ($var,$val) = ($1,$2);
      # Replace "." by "_" in var name
      $var =~ s/\./_/g;
      # Replace "\" by "/" and double quotes by single quotes
      #$val =~ s/"/'"'"'/g;
      $val =~ s/"//g;
      $val =~ s/\\/\//g;
      # Concatenate name and value to go on processing
      $_ = "$var$val";
      #$_ = "$var\"$val\"";

      # Replace %DOS-STYLE% variables by ${SHELL-STYLE} variables
      while (m/(.*?)%([^\s]+)%(.*)/)
      {
        my ($var,$val,$rest) = ($1,$2,$3);
        $val =~ s/\./_/g;
        $_ = $var."\${".$val."}".$rest;
      }

      # Print out the export command for evaluation
      print "$_\n";
    }
  ' "$SSH_CONFIG_FILE"
}

# Select an host and load its configuration
function _ssh-selecthost() {
  # Clean up environment and load hosts settings
  ID="${1:-$SSHPACK_HOSTID}"
  if [[ ! -n "$ID" || $ID == "0" ]]; then
    echo Reload configuration file...
    unset $(env | grep SSHPACK_ | grep -v SSHPACK_PATH | sed -re 's/([^\=]*)=.*/\1/')
    IFS=$'\n' # End of Field is \n
    for exp in $(_ssh-printconfig); do
      export $exp
    done
    IFS=$' \t\n'
  fi

  # Ask for a new host ID if not valid
  VAR=SSHPACK_${ID}_NAME
  while [ ! -n "${!VAR}" ]; do
    echo $SSHPACK_NAMES
    echo -n "Host ID: " && read ID
    VAR=SSHPACK_${ID}_NAME
  done

  # Export all selected host variables if changed
  if [ "$ID" != "$SSHPACK_HOSTID" ]; then
    echo Export sshpack variables...
    IFS=$'\n' # End of Field is \n
    for exp in $(env | grep -i ^SSHPACK_${ID} | sed -e "s/_${ID}//" -e "s/=\(.*\)/=\1/" -e 's@${SSHPACK_DIR}@'"${SSHPACK_DIR}"'@'); do
      export $exp
    done
    IFS=$' \t\n'
    export SSHPACK_PKEY=${SSHPACK_PATH}/${SSHPACK_PKEY%????}
    # Store host ID
    export SSHPACK_HOSTID="$ID"
  fi
}

function ssh-config() {
  #_ssh-printconfig
  _ssh-selecthost "$@"
}
