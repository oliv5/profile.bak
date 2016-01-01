#!/bin/sh

################################
# To lower
toLower() {
  echo "${@}" | tr "[:upper:]" "[:lower:]"
}

# To upper
toUpper() {
  echo "${@}" | tr "[:lower:]" "[:upper:]"
}

################################
# Ask question and expect one of the given answer
# ask_question [fd number] [question] [expected replies]
ask_question() {
  # -- Generic part --
  local REPLY
  local STDIN=/dev/fd/0
  if [ -c "/dev/fd/$1" ]; then
    STDIN=/dev/fd/$1
    shift $(min 1 $#)
  fi
  read ${1:+-p "$1"} REPLY <${STDIN}
  shift $(min 1 $#)
  # -- Custom part --
  echo "$REPLY"
  for ACK; do
    [ "$REPLY" = "$ACK" ] && return 0
  done
  return 1
}

# Ask for a file
# ask_file [fd number] [question] [file test] [default value]
ask_file() {
  # -- Generic part --
  local REPLY
  local STDIN=/dev/fd/0
  if [ -c "/dev/fd/$1" ]; then
    STDIN=/dev/fd/$1
    shift $(min 1 $#)
  fi
  read ${1:+-p "$1"} REPLY <${STDIN}
  shift $(min 1 $#)
  # -- Custom part --
  [ -z "$REPLY" ] && REPLY="$2"
  echo "$REPLY"
  test ${1:-e} "$REPLY"
}

# Get password
ask_passwd() {
  local PASSWD
  trap "stty echo; trap INT" INT; stty -echo
  read -p "${1:-Password: }" PASSWD; echo
  stty echo; trap - INT
  echo $PASSWD
}

################################
# Create file backup
mkbak() {
  cp "${1:?Please specify input file 1}" "${1}.$(date +%Y%m%d-%H%M%S).bak"
}

################################
# Convert HH:mm:ss.ms into seconds
toSec(){
  echo "$1" | awk -F'[:.]' '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }'
}
toSecMs(){
  echo "$1" | awk -F: '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }'
}
toMs(){
  echo "$1" | awk -F: '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print (($1 * 3600) + ($2 * 60) + $3) * 1000 }'
}

################################
# Convert to libreoffice formats
conv_soffice() {
  local FORMAT="${1:?No output format specified}"
  shift $(min 1 $#)
  unoconv -f "$FORMAT" "$@" ||
    soffice --headless --convert-to "$FORMAT" "$@"
}

# Convert to PDF
conv_pdf() {
  # sudo apt-get install wv texlive-base texlive-latex-base ghostscript
  for FILE in "$@"; do
    wvPDF "$FILE" "${FILE%.*}.pdf"
  done
}

# Merge PDFs
merge_pdf() {
  local INPUT="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  eval command -p gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="$@" "$INPUT"
}

# Tex to pdf
alias tex2pdf='pdflatex --interaction nonstopmode'
alias tex2pdf_loop='watch -n 15 "pdflatex --interaction nonstopmode >/dev/null 2>&1"'
