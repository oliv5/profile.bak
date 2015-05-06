#!/bin/sh
DFEXCLUDE="-not -path *.svn* -and -not -path *.git*"
DGEXCLUDE="--exclude-dir=.svn --exclude-dir=.git"
DSEXCLUDE="$DFEXCLUDE -not -type l"

# Dev grep
# Various dev search function helpers
_dgrep() { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; shift $(min 3 $#); (set -f; _fgrep "$ARG2" ${GCASE} ${DGEXCLUDE} "$@" "${ARG3:-.}/$ARG1"); }
alias _c='_dgrep "*.c;*.cpp;*.cc"'
alias _h='_dgrep "*.h;*.hpp"'
alias _v='_dgrep "*.vhd;*.v"'
alias _hc='_dgrep "*.c;*.cpp;*.cc;*.h;*.hpp"'
alias _py='_dgrep "*.py"'
alias _mk='_dgrep "*.mk;Makefile"'
alias _asm='_dgrep "*.inc;*.S"'
alias _xml='_dgrep "*.xml"'
alias _ref='_dgrep "*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S"'
alias _shell='_dgrep "*.sh"'
alias c='GCASE=   _c'
alias h='GCASE=   _h'
alias v='GCASE=   _v'
alias hc='GCASE=   _hc'
alias py='GCASE=   _py'
alias mk='GCASE=   _mk'
alias asm='GCASE=   _asm'
alias xml='GCASE=   _xml'
alias ref='GCASE=   _ref'
alias shell='GCASE=   _shell'
alias ic='GCASE=-i _c'
alias ih='GCASE=-i _h'
alias iv='GCASE=-i _v'
alias ihc='GCASE=-i _hc'
alias ipy='GCASE=-i _py'
alias imk='GCASE=-i _mk'
alias iasm='GCASE=-i _asm'
alias ixml='GCASE=-i _xml'
alias iref='GCASE=-i _ref'
alias ishell='GCASE=-i _shell'

# Code elements search
#REGEX_FUNC='(^|\s+|::)NAME\s*\(([^;]*$|[^\}]\})'
REGEX_FUNC='\w+\s+NAME\s*\(\s*($|\w+\s+\w+|void)'
REGEX_VAR='^[^\(]*\w+\s*(\*|&)*\s*NAME\s*(=.+|\(\w+\)|\[.+\])?\s*(;|,)'
REGEX_STRUCT='(struct|union|enum|class)\s*NAME\s*(\{|$)'
REGEX_TYPEDEF='(typedef\s+\w+\sNAME)|(^\s*NAME\s*;)'
REGEX_DEFINE='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
_dsearch() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; _ref "${ARG1//NAME/$ARG2}" . -E "$@"); }
alias def='GCASE=   _dsearch "($REGEX_FUNC)|($REGEX_VAR)|($REGEX_STRUCT)|($REGEX_DEFINE)|($REGEX_TYPEDEF)"'
alias var='GCASE=   _dsearch "$REGEX_VAR"'
alias func='GCASE=   _dsearch "$REGEX_FUNC"'
alias struct='GCASE=   _dsearch "$REGEX_STRUCT"'
alias define='GCASE=   _dsearch "$REGEX_DEFINE"'
alias typedef='GCASE=   _dsearch "$REGEX_TYPEDEF"'
alias idef='GCASE=-i _dsearch "($REGEX_FUNC)|($REGEX_VAR)|($REGEX_STRUCT)|($REGEX_DEFINE)|($REGEX_TYPEDEF)"'
alias ivar='GCASE=-i _dsearch "$REGEX_VAR"'
alias ifunc='GCASE=-i _dsearch "$REGEX_FUNC"'
alias istruct='GCASE=-i _dsearch "$REGEX_STRUCT"'
alias idefine='GCASE=-i _dsearch "$REGEX_DEFINE"'
alias itypedef='GCASE=-i _dsearch "$REGEX_TYPEDEF"'

# Dev replace
alias  dhh='SEXCLUDE="$DSEXCLUDE" hh'
alias idhh='SEXCLUDE="$DSEXCLUDE" ihh'

# Hexdump to txt 32 bits
bin2hex32() {
  hexdump $@ -ve '1/4 "0x%.8x\n"'
}
