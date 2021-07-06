#!/bin/sh

# Find file in a CVS, fallback to std file search otherwise
alias dff='_dfind'
_dfind() { if git_exists "$(dirname "$1")"; then git ls-files "*$@"; elif svn_exists "$(dirname "$1")"; then svn ls -R "$(dirname "$1")" | grep -E "$@"; else _ffind "$@"; fi; }

# Find a CVS root folder
alias rffd='_rfind'
_rfind() { if svn_exists "$@"; then svn_root "$@"; elif git_exists "$@"; then git_worktree "$@"; fi };

# Grep based code search
_dgrep1()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; [ $# -lt 3 ] && shift $# || shift 3; (set -f; FARGS="${_DG1EXCLUDE} $@" _fgrep1 "$ARG2" "${ARG3:-.}/$ARG1"); }
_dgrep2()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; [ $# -lt 3 ] && shift $# || shift 3; (set -f; _fgrep2 "$ARG2" ${_DG2EXCLUDE} "$@" "${ARG3:-.}/$ARG1"); }
_dgrep3()   { local ARG1="$1"; local ARG2="$2"; local ARG3="$3"; [ $# -lt 3 ] && shift $# || shift 3; (set -f; git grep -nE ${GCASE} ${GARGS} "$@" "$ARG2" -- $(echo "$ARG1" | sed "s@^@${ARG3:-.}/*@ ; s@;@ ${ARG3:-.}/*@g")); }
_dgrep()    { if git_exists "$3"; then _dgrep3 "$@"; else _dgrep1 "$@"; fi; }
_DG1EXCLUDE=""
_DG2EXCLUDE="--exclude-dir=.*"
_DGEXT_C="*.c;*.cpp;*.cc"
_DGEXT_H="*.h;*.hpp"
_DGEXT_V="*.vhd;*.v;*.sv"
_DGEXT_PY="*.py"
_DGEXT_SCONS="SConstruct;SConscript;sconstruct;sconscript"
_DGEXT_MK="*.mk;Makefile;makefile;GNUmakefile;gnumakefile;$_DGEXT_SCONS"
_DGEXT_ASM="*.inc;*.S;*.s"
_DGEXT_XML="*.xml"
_DGEXT_TEX="*.tex"
_DGEXT_SHELL="*.sh"
_DGEXT_REF="$_DGEXT_C;$_DGEXT_H;$_DGEXT_V;$_DGEXT_PY;$_DGEXT_SCONS;$_DGEXT_MK;$_DGEXT_ASM;$_DGEXT_XML;$_DGEXT_SHELL"
alias      c='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_C"'
alias      h='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_H"'
alias      v='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_V"'
alias     ch='FCASE= FTYPE=  FXTYPE= FARGS= GCASE=   GARGS= _dgrep "$_DGEXT_C;$_DGEXT_H"'
alias     hc='ch'
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
alias    ihc='ich'
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
_DGREGEX_TYPEDEF='(typedef\s+\w+\s+NAME)|(^\s*NAME\s*;)'
_DGREGEX_DEFINE='(#define\s+NAME|^\s*NAME\s*,)|(^\s*NAME\s*=.*,)'
_DGREGEX_ALL="($_DGREGEX_FUNC)|($_DGREGEX_VAR)|($_DGREGEX_STRUCT)|($_DGREGEX_TYPEDEF)|($_DGREGEX_DEFINE)"
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

# Dev replace
#_DSEXCLUDE="-not -path */.svn* -and -not -path */.git* -and -not -type l"
_DSEXCLUDE="-not -path '*/.*' -and -not -type l"
alias  dhh='FCASE=   FTYPE= FXTYPE= FARGS= SFILES="$_DGEXT_REF" SEXCLUDE="$_DSEXCLUDE" _fsed2'
alias idhh='FCASE=-i FTYPE= FXTYPE= FARGS= SFILES="$_DGEXT_REF" SEXCLUDE="$_DSEXCLUDE" _fsed2'

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

# Tab vs spaces
space2tab() {
	local FILES="${1:?No files defined...}"
	local TABSIZE="${2:-4}"
	local TABNUM="${3:-10}"
	_ffind "$FILES" -type f -print0 | xargs -r0 -- sh -c '
		TABSIZE="$1"
		TABNUM="$2"
		shift 2
		for FILE; do
			for N in $(seq "$TABNUM" -1 1); do
				sed -r -i -e "s/^(\t*)( {$TABSIZE})/\1\t/" "$FILE"
			done
		done
	' _ "$TABSIZE" "$TABNUM"
}
tab2space() {
	local FILES="${1:?No files defined...}"
	local TABSIZE="${2:-4}"
	local TABNUM="${3:-10}"
	local SPACES=""
	for N in $(seq $TABSIZE); do SPACES="${SPACES} "; done
	_ffind "$FILES" -type f -print0 | xargs -r0 -- sh -c '
		TABSIZE="$1"
		TABNUM="$2"
		SPACES="$3"
		shift 3
		for FILE; do
			for N in $(seq "$TABNUM" -1 1); do
				sed -r -i -e "s/^( *)\t/\1$SPACES/" "$FILE"
			done
		done
	' _ "$TABSIZE" "$TABNUM" "$SPACES"
}

# Uncrustify
uncrust() {
	command -v uncrustify >/dev/null 2>&1 && echo "ERROR: cannot find uncrustify..." && return 1
	local CFG="${XDG_CONFIG_HOME:-$HOME/.config}/uncrustify/${2:-$(uncrustify --version)}.cfg"
	find "${1:?No source folder specified...}" -type f -regex '.*\.\(c\|h\|cpp\|cc\|hpp\)' -print0 | xargs -r0 -n1 -- uncrustify -c "$CFG" --no-backup -f
}
