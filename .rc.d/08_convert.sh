#!/bin/sh

################################
# Computations
min() { echo $(($1<$2?$1:$2)); }
max() { echo $(($1>$2?$1:$2)); }
lim() { max $(min $1 $3) $2; }
isint() { expr 2 "*" "$1" + 1 >/dev/null 2>&1; }

# Conversion to integer using printf
_int() {
  local MAX="${1:?No maximum value specified...}"
  shift
  for NUM; do
    local RES=$(printf "%d" "$NUM")
    [ $RES -ge $MAX ] && RES=$((RES-2*MAX))
    echo $RES
  done
}
alias int='int32'
alias int8='_int $((1<<7))'
alias int16='_int $((1<<15))'
alias int32='_int $((1<<31))'
alias int64='_int $((1<<63))'

# Conversion to unsigned integer using printf
_uint() {
  for NUM; do
    printf "%d\n" "$NUM"
  done
}
alias uint='_uint'
alias uint8='_uint'
alias uint16='_uint'
alias uint32='_uint'
alias uint64='_uint'

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}

################################
# Return a string with uniq words
alias str_uniqw='str_uniq " " " "'
str_uniq() {
  local _IFS="${1:- }"
  local _OFS="${2}"
  shift 2
  #printf -- '%s\n' $@ | sort -u | xargs
  printf -- "$@" | awk -vRS="$_IFS" -vORS="$_OFS" '!seen[$0]++ {str=str$1ORS} END{sub(ORS"$", "", str); printf "%s\n",str}'
}

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
# Convert HH:mm:ss.ms into seconds
toSec(){
  for INPUT; do
    echo "$INPUT" | awk -F'[:.]' '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }'
  done
}
toSecMs(){
  for INPUT; do
    echo "$INPUT" | awk -F: '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print ($1 * 3600) + ($2 * 60) + $3 }'
  done
}
toMs(){
  for INPUT; do
    echo "$INPUT" | awk -F: '{ for(i=0;i<2;i++){if(NF<=2){$0=":"$0}}; print (($1 * 3600) + ($2 * 60) + $3) * 1000 }'
  done
}

################################
# Convert to openoffice formats
conv_openoffice() {
  local FORMAT="${1:?No output format specified}"
  shift $(min 1 $#)
  unoconv -f "$FORMAT" "$@" ||
    soffice --headless --convert-to "$FORMAT" "$@"
}

# Convert to libreoffice formats
conv_libreoffice() {
  local FORMAT="${1:?No output format specified}"
  shift $(min 1 $#)
  soffice --headless --convert-to "$FORMAT" "$@"
}

# Convert to PDF using wvpdf
conv_wvpdf() {
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
