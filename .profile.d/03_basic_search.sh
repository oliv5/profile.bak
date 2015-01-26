#!/bin/sh
# Bash utils
############################################

toLower()
{
  echo "${@}" | tr "[:upper:]" "[:lower:]"
}

toUpper()
{
  echo "${@}" | tr "[:lower:]" "[:upper:]"
}

multiColorString()
{
  for letterNbr in `seq ${#1}`
  do
    let "RANDOM_COLOR = ${RANDOM} % 8"
    let "POSITION = ${letterNbr} - 1"
    letter="`toLower "${1:${POSITION}:1}"`"
    case "${letter}" in
      a)
        ;;
      e)
        ;;
      i)
        ;;
      o)
        ;;
      u)
        ;;
      y)
        ;;
      *)
        letter="`toUpper "${letter}"`"
        ;;
    esac
    echo -ne "\033[01;3${RANDOM_COLOR}m${letter}\033[00m"
  done
  echo ""
}

#############################################################################
# Safe find & replace
#############################################################################

rpl()
{
  if [[ $# != 4 ]]
  then
    multiColorString "Invalid number of arguments!!!"
    echo "Usage : $0 <file name pattern> <pattern to replace> <with this pattern> <from this directory on>"
  elif ! [[ -d "${4}" ]]
  then
    multiColorString "Bad bad directory : ${4}"
  else
    find ${4} -name "${1}" -and -not -type l -and -not -path "*.svn*" -and -not -path "*obj*" -and -not -path "*.git" -exec sed -i "s/${2}/${3}/g" {} \;
  fi
}

#############################################################################
# VI wrapper. You can call vim path_to_file/file.c:56. It will open
# the file at the right line
#############################################################################

v()
{
  args=""
  if [[ $# = 1 ]]
  then
    pyCmd="a=\"${1}\".split(\":\"); b = a[0] if (len(a) = 1) else \"%s +%s\" % (a[0], a[1]); print b;"
    args=`python -c "${pyCmd}"`
  fi
  vim ${args}
}

#############################################################################
# Search core function
#############################################################################

_search()
{
  if [[ $# = 0 ]]
  then
    multiColorString "Invalid number of arguments!!! $0 <string> [file extensions]"
    return
  fi
  base_opts="--color -nr"
  base_excs="--exclude-dir=.svn --exclude=.git --exclude-dir=call-* --exclude-dir=obj --exclude=tags"
  s="${1}"
  shift
  incs=""
  while (( "$#" )); do
    incs="${incs} --include=${1}"
    shift
  done
  grep ${base_opts} ${base_excs} ${incs} "${s}" *
}

#############################################################################
# Search in header files
#############################################################################

h()
{
  _search "${1}" "*.h" "*.hpp"
}

#############################################################################
# Search in source files
#############################################################################

c()
{
  _search "${1}" "*.c" "*.cpp" "*.cc"
}

#############################################################################
# Search in python scripts
#############################################################################

py()
{
  _search "${1}" "*.py"
}

#############################################################################
# Search in build system
#############################################################################

mk()
{
  _search "${1}" "Makefile" "*.mk"
}

