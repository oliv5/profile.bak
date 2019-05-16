#!/bin/sh

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
# Convert to openoffice/libreoffice formats
conv_lo() {
  local FORMAT="${1:-?No output format specified}" && shift
  command -v unoconv >/dev/null && unoconv -f "$FORMAT" "$@" ||
    soffice --headless --convert-to "$FORMAT" "$@"
}
conv_lopdf() {
  conv_lo pdf "$@"
}

# Convert to PDF using wvpdf
conv_wvpdf() {
  # sudo apt-get install wv texlive-base texlive-latex-base ghostscript
  for FILE in "$@"; do
    wvPDF "$FILE" "${FILE%.*}.pdf"
  done
}

################################
# Merge PDFs
pdf_merge() {
  local INPUT="$(arg_rtrim 1 "$@")"; shift $(($#-1))
  eval command -p gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="$@" "$INPUT"
}

# Tex to pdf
alias tex2pdf='latex2pdf'
latex2pdf() {
  for FILE in "$@"; do
    pdflatex --interaction nonstopmode -output-directory="$(dirname "$FILE")" "$FILE"
  done
}

latex2pdf_loop() {
  watch -n 15 "tex2pdf "$@">/dev/null 2>&1"
}

latex2pdf_modified() {
  local IFS=$'\n'
  for FILE in $(svn_st "^[^\?\X\P]" 2>/dev/null | grep '.tex\"') $(git_st "M" 2>/dev/null | grep '.tex\"'); do
    eval FILE="$FILE"
    ( command cd "$(dirname "$FILE")"
      latex2pdf "$(basename "$FILE")"
    )
  done
}

# PDF to booklet
alias pdf2booklet='pdfbook --short-edge'

# Search into pdf
pdf_search() {
  local PATTERN="$1"
  shift
  ff "$@/*.pdf" -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color '"$PATTERN" \;
}

# Shuffle 2 pdf pages
pdf_shuffle() {
  pdftk A="${1:?No recto pdf specified...}" B="${2:?No verso pdf specified...}" shuffle A Bend-1 output "${3:-output.pdf}"
}
