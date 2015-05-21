#!/bin/sh

# Grep based code search
_dgrep1()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; shift $(min 3 $#); (set -f; _fgrep "$ARG2" ${_DGEXCLUDE} "$@" "${ARG3:-.}/$ARG1"); }
_DGEXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
_DGEXT_C="*.c;*.cpp;*.cc"
_DGEXT_H="*.h;*.hpp"
_DGEXT_V="*.vhd;*.v"
_DGEXT_HC="*.c;*.cpp;*.cc;*.h;*.hpp"
_DGEXT_PY="*.py"
_DGEXT_MK="*.mk;Makefile"
_DGEXT_ASM="*.inc;*.S"
_DGEXT_XML="*.xml"
_DGEXT_SHELL="*.sh"
_DGEXT_REF="*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S"
alias      c='GCASE=   _dgrep1 "$_DGEXT_C"'
alias      h='GCASE=   _dgrep1 "$_DGEXT_H"'
alias      v='GCASE=   _dgrep1 "$_DGEXT_V"'
alias     hc='GCASE=   _dgrep1 "$_DGEXT_HC"'
alias     py='GCASE=   _dgrep1 "$_DGEXT_PY"'
alias     mk='GCASE=   _dgrep1 "$_DGEXT_MK"'
alias    asm='GCASE=   _dgrep1 "$_DGEXT_ASM"'
alias    xml='GCASE=   _dgrep1 "$_DGEXT_XML"'
alias  shell='GCASE=   _dgrep1 "$_DGEXT_SHELL"'
alias    ref='GCASE=   _dgrep1 "$_DGEXT_REF"'
alias     ic='GCASE=-i _dgrep1 "$_DGEXT_C"'
alias     ih='GCASE=-i _dgrep1 "$_DGEXT_H"'
alias     iv='GCASE=-i _dgrep1 "$_DGEXT_V"'
alias    ihc='GCASE=-i _dgrep1 "$_DGEXT_HC"'
alias    ipy='GCASE=-i _dgrep1 "$_DGEXT_PY"'
alias    imk='GCASE=-i _dgrep1 "$_DGEXT_MK"'
alias   iasm='GCASE=-i _dgrep1 "$_DGEXT_ASM"'
alias   ixml='GCASE=-i _dgrep1 "$_DGEXT_XML"'
alias ishell='GCASE=-i _dgrep1 "$_DGEXT_SHELL"'
alias   iref='GCASE=-i _dgrep1 "$_DGEXT_REF"'

# Grep based code block search
_dsearch1() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _dgrep1 $_DGEXT_REF "${ARG1//NAME/$ARG2}" . -E "$@"); }
#_DGREGEX_FUNC='(^|\s+|::)NAME\s*\(([^;]*$|[^\}]\})'
_DGREGEX_FUNC='\w+\s+NAME\s*\(\s*($|\w+\s+\w+|void)'
_DGREGEX_VAR='^[^\(]*\w+\s*(\*|&)*\s*NAME\s*(=.+|\(\w+\)|\[.+\])?\s*(;|,)'
_DGREGEX_STRUCT='(struct|union|enum|class)\s*NAME\s*(\{|$)'
_DGREGEX_TYPEDEF='(typedef\s+\w+\sNAME)|(^\s*NAME\s*;)'
_DGREGEX_DEFINE='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
_DGREGEX_ALL='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
alias      def='GCASE=   _dsearch "$_DGREGEX_ALL"'
alias      var='GCASE=   _dsearch "$_DGREGEX_VAR"'
alias     func='GCASE=   _dsearch "$_DGREGEX_FUNC"'
alias   struct='GCASE=   _dsearch "$_DGREGEX_STRUCT"'
alias   define='GCASE=   _dsearch "$_DGREGEX_DEFINE"'
alias  typedef='GCASE=   _dsearch "$_DGREGEX_TYPEDEF"'
alias     idef='GCASE=-i _dsearch "$_DGREGEX_ALL"'
alias     ivar='GCASE=-i _dsearch "$_DGREGEX_VAR"'
alias    ifunc='GCASE=-i _dsearch "$_DGREGEX_FUNC"'
alias  istruct='GCASE=-i _dsearch "$_DGREGEX_STRUCT"'
alias  idefine='GCASE=-i _dsearch "$_DGREGEX_DEFINE"'
alias itypedef='GCASE=-i _dsearch "$_DGREGEX_TYPEDEF"'

# Dev replace
_DSEXCLUDE="-not -path *.svn* -and -not -path *.git* -and -not -type l"
alias  dhh='SEXCLUDE="$_DSEXCLUDE" hh'
alias idhh='SEXCLUDE="$_DSEXCLUDE" ihh'

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}
