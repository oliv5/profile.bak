#!/bin/sh

# Find based code search
_dfind1() { local ARG1="$1"; shift; (set -f; _ffind "$ARG1" ${_DFEXCLUDE} "$@"); }
alias _dfind='_dfind1'
#_DFEXCLUDE="-and -not -path */.svn* -and -not -path */.git* -and -not -path */.repo*"
_DFEXCLUDE="-and -not -path */.*"
alias    dff='FCASE=   FTYPE=  FXTYPE=  FARGS= _dfind'
alias   dfff='FCASE=   FTYPE=f FXTYPE=  FARGS= _dfind'
alias   dffd='FCASE=   FTYPE=d FXTYPE=  FARGS= _dfind'
alias   dffl='FCASE=   FTYPE=l FXTYPE=  FARGS= _dfind'
alias  dffll='FCASE=   FTYPE=l FXTYPE=f FARGS= _dfind'
alias  dfflb='FCASE=   FTYPE=l FXTYPE=l FARGS= _dfind'
alias   idff='FCASE=-i FTYPE=  FXTYPE=  FARGS= _dfind'
alias  idfff='FCASE=-i FTYPE=f FXTYPE=  FARGS= _dfind'
alias  idffd='FCASE=-i FTYPE=d FXTYPE=  FARGS= _dfind'
alias  idffl='FCASE=-i FTYPE=l FXTYPE=  FARGS= _dfind'
alias idffll='FCASE=-i FTYPE=l FXTYPE=f FARGS= _dfind'
alias idfflb='FCASE=-i FTYPE=l FXTYPE=l FARGS= _dfind'

# Grep based code search
_dgrep1()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; shift $(min 3 $#); (set -f; FARGS="${_DG1EXCLUDE} $@" _fgrep1 "$ARG2" "${ARG3:-.}/$ARG1"); }
_dgrep2()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; shift $(min 3 $#); (set -f; _fgrep2 "$ARG2" ${_DG2EXCLUDE} "$@" "${ARG3:-.}/$ARG1"); }
_dgrep()    { [ -n "$(git_root 2>/dev/null)" -a $# -le 2 ] && git grep "$2" || _dgrep1 "$@"; }
_DG1EXCLUDE="$_DFEXCLUDE"
#_DG2EXCLUDE="--exclude-dir=.svn --exclude-dir=.git --exclude-dir=.repo"
_DG2EXCLUDE="--exclude-dir=.*"
_DGEXT_C="*.c;*.cpp;*.cc"
_DGEXT_H="*.h;*.hpp"
_DGEXT_V="*.vhd;*.v"
_DGEXT_PY="*.py"
_DGEXT_MK="*.mk;Makefile"
_DGEXT_ASM="*.inc;*.S"
_DGEXT_XML="*.xml"
_DGEXT_TEX="*.tex"
_DGEXT_SHELL="*.sh"
_DGEXT_REF="*.c;*.cpp;*.cc;*.h;*.hpp;*.py;*.mk;Makefile;*.sh;*.vhd;*.v;*.inc;*.S;*.tex;*.lua"
alias      c='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_C"'
alias      h='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_H"'
alias      v='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_V"'
alias     ch='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_C;$_DGEXT_H"'
alias     py='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_PY"'
alias     mk='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_MK"'
alias    asm='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_ASM"'
alias    xml='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_XML"'
alias    tex='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_TEX"'
alias  shell='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_SHELL"'
alias    ref='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_REF"'
alias     ic='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_C"'
alias     ih='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_H"'
alias     iv='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_V"'
alias    ich='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_C;$_DGEXT_H"'
alias    ipy='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_PY"'
alias    imk='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_MK"'
alias   iasm='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_ASM"'
alias   ixml='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_XML"'
alias   itex='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_TEX"'
alias ishell='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_SHELL"'
alias   iref='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dgrep "$_DGEXT_REF"'

# Grep based code block search
_dsearch1() { local ARG1="$1"; local ARG2="$2"; shift $(min 2 $#); (set -f; GARGS=-E _dgrep $_DGEXT_REF "${ARG1//NAME/$ARG2}" "$@"); }
alias _dsearch='_dsearch1'
#_DGREGEX_FUNC='(^|\s+|::)NAME\s*\(([^;]*$|[^\}]\})'
_DGREGEX_FUNC='\w+\s+NAME\s*\(\s*($|\w+\s+\w+|void)'
_DGREGEX_VAR='^[^\(]*\w+\s*(\*|&)*\s*NAME\s*(=.+|\(\w+\)|\[.+\])?\s*(;|,)'
_DGREGEX_STRUCT='(struct|union|enum|class)\s*NAME\s*(\{|$)'
_DGREGEX_TYPEDEF='(typedef\s+\w+\sNAME)|(^\s*NAME\s*;)'
_DGREGEX_DEFINE='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
_DGREGEX_ALL='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
alias      def='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_ALL"'
alias      var='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_VAR"'
alias     func='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_FUNC"'
alias   struct='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_STRUCT"'
alias   define='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_DEFINE"'
alias  typedef='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dsearch "$_DGREGEX_TYPEDEF"'
alias     idef='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_ALL"'
alias     ivar='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_VAR"'
alias    ifunc='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_FUNC"'
alias  istruct='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_STRUCT"'
alias  idefine='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_DEFINE"'
alias itypedef='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=-i GARGS= _dsearch "$_DGREGEX_TYPEDEF"'

# Alias to cut part of search result
alias c1='cut -d: -f 1'
alias c2='cut -d: -f 2'
alias c3='cut -d: -f 3'

# Dev replace
#_DSEXCLUDE="-not -path */.svn* -and -not -path */.git* -and -not -type l"
_DSEXCLUDE="-not -path */.* -and -not -type l"
alias  dhh='FCASE=   FTYPE= FXTYPE= FARGS= SEXCLUDE="$_DSEXCLUDE" _fsed'
alias idhh='FCASE=-i FTYPE= FXTYPE= FARGS= SEXCLUDE="$_DSEXCLUDE" _fsed'

# Parallel make (needs ipcmd tool)
# https://code.google.com/p/ipcmd/wiki/ParallelMake
pmake() {
	# Call make protected by semaphores when ipcmd is available
	# Otherwise call make directly
	if command -v ipcmd >/dev/null; then
		local IPCMD_SEMID="$(ipcmd semget)"
		local AR="ipcmd semop -s $IPCMD_SEMID -u -1 : ar"
		local RANLIB="ipcmd semop -s $IPCMD_SEMID -u -1 : ranlib"
		local PYTHON="ipcmd semop -s $IPCMD_SEMID -u -1 : python"
		local TRAP="ipcrm -s '$IPCMD_SEMID'; trap INT"
		ipcmd semctl -s "$IPCMD_SEMID" setall 1
		trap "ipcrm -s '$TRAP'" INT
		make AR="$AR" RANLIB="$RANLIB" PYTHON="$PYTHON" "$@"
		local RETCODE=$?
		eval "$TRAP"
		return $RETCODE
	else
		make "$@"
	fi
}
