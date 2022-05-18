#!/bin/sh
# From https://github.com/direnv/direnv/blob/master/stdlib.sh
# Depends on 01_path.sh

use_julia() {
  export JULIA_PROJECT=$PWD
}

use_go() {
  _path_append GOPATH "${1:-$PWD}/go"
  path_append "${1:-$PWD}/go/bin"
}

use_perl() {
  local LIBDIR
  LIBDIR="${1:-$PWD}/perl5"
  export LOCAL_LIB_DIR="$LIBDIR"
  export PERL_MB_OPT="--install_base '$LIBDIR'"
  export PERL_MM_OPT="INSTALL_BASE=$LIBDIR"
  path_append PERL5LIB "$LIBDIR/lib/perl5"
  path_append PERL_LOCAL_LIB_ROOT "$LIBDIR"
  path_append "$LIBDIR/bin"
}

use_php() {
  path_append "${1:-$PWD}/vendor/bin"
}

# Usage: use_python <python_exe> <workpath>
#
# Creates and loads a virtual environment under
# "$workpath/python-$python_version".
# This forces the installation of any egg into the project's sub-folder.
# For python older then 3.3 this requires virtualenv to be installed.
#
# It's possible to specify the python executable if you want to use different
# versions of python.
#
use_python() {
  local old_env
  local python="${1:-python}"
  [ $# -gt 0 ] && shift
  old_env="${2:-$PWD}/virtualenv"
  unset PYTHONHOME
  if [ -d "$old_env" ] && [ "$python" = "python" ]; then
    VIRTUAL_ENV="$old_env"
  else
    local python_version ve

    #read -r python_version ve <<<$($python -c "import pkgutil as u, platform as p;ve='venv' if u.find_loader('venv') else ('virtualenv' if u.find_loader('virtualenv') else '');print(p.python_version()+' '+ve)")
    python_version="$($python -c "import pkgutil as u, platform as p;ve='venv' if u.find_loader('venv') else ('virtualenv' if u.find_loader('virtualenv') else '');print(p.python_version()+' '+ve)")"
    ve="${python_version##* }"
    python_version="${python_version%% *}"

    if [ -z $python_version ]; then
      echo >&2 "Could not find python's version"
      return 1
    fi

    VIRTUAL_ENV="${2:-$PWD}/python-$python_version"
    case $ve in
      "venv")
        if [ ! -d "$VIRTUAL_ENV" ]; then
          $python -m venv "$@" "$VIRTUAL_ENV"
        fi
        ;;
      "virtualenv")
        if [ ! -d "$VIRTUAL_ENV" ]; then
          $python -m virtualenv "$@" "$VIRTUAL_ENV"
        fi
        ;;
      *)
        echo >&2 "Error: neither venv nor virtualenv are available."
        return 1
        ;;
    esac
  fi
  export VIRTUAL_ENV
  path_append "$VIRTUAL_ENV/bin"
}

use_python2() {
  use_python python2 "$@"
}

use_python3() {
  use_python python3 "$@"
}

# Similar to use_python, but uses Pipenv to build a
# virtualenv from the Pipfile located in the same directory.
#
use_pipenv() {
  PIPENV_PIPFILE="${PIPENV_PIPFILE:-Pipfile}"
  if [ ! -f "$PIPENV_PIPFILE" ]; then
    echo >&2 "No Pipfile found.  Use \`pipenv\` to create a \`$PIPENV_PIPFILE\` first."
    exit 2
  fi

  VIRTUAL_ENV=$(pipenv --venv 2>/dev/null ; true)

  if [ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]; then
    pipenv install --dev
    VIRTUAL_ENV=$(pipenv --venv)
  fi

  path_append "$VIRTUAL_ENV/bin"
  export PIPENV_ACTIVE=1
  export VIRTUAL_ENV
}

# Usage: use_pyenv <python version number> [<python version number> ...]
#
# Uses pyenv and use_python to create and load a virtual environment under
# "$direnv_layout_dir/python-$python_version".
#
use_pyenv() {
  unset PYENV_VERSION
  # use_python prepends each python version to the PATH, so we add each
  # version in reverse order so that the first listed version ends up
  # first in the path
  local i
  for ((i = $#; i > 0; i--)); do
    local python_version=${!i}
    local pyenv_python
    pyenv_python=$(pyenv root)/versions/${python_version}/bin/python
    if [ -x "$pyenv_python" ]; then
      if use_python "$pyenv_python"; then
        # e.g. Given "use pyenv 3.6.9 2.7.16", PYENV_VERSION becomes "3.6.9:2.7.16"
        PYENV_VERSION=${python_version}${PYENV_VERSION:+:$PYENV_VERSION}
      fi
    else
      echo >&2 "pyenv: version '$python_version' not installed"
      return 1
    fi
  done

  [ -n "$PYENV_VERSION" ] && export PYENV_VERSION
}

# Sets the GEM_HOME environment variable to "${1:-$PWD}/ruby/RUBY_VERSION".
# This forces the installation of any gems into the project's sub-folder.
# If you're using bundler it will create wrapper programs that can be invoked
# directly instead of using the $(bundle exec) prefix.
#
use_ruby() {
  BUNDLE_BIN="${1:-$PWD}/bin"

  if ruby -e "exit Gem::VERSION > '2.2.0'" 2>/dev/null; then
    GEM_HOME="${1:-$PWD}/ruby"
  else
    local RUBY_VERSION
    RUBY_VERSION="$(ruby -e"puts (defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby') + '-' + RUBY_VERSION")"
    GEM_HOME="${1:-$PWD}/ruby-${RUBY_VERSION}"
  fi

  export BUNDLE_BIN
  export GEM_HOME

  path_append "$GEM_HOME/bin"
  path_append "$BUNDLE_BIN"
}

# Loads rbenv which add the ruby wrappers available on the PATH.
# https://github.com/rbenv/rbenv
use_rbenv() {
  eval "$(rbenv init -)"
}

# Ruby Version Manager (RVM)
# https://rvm.io/
use_rvm() {
  unset rvm
  if [ -n ${rvm_scripts_path:-} ]; then
    # shellcheck disable=SC1090,SC1091
    source "${rvm_scripts_path}/rvm"
  elif [ -n ${rvm_path:-} ]; then
    # shellcheck disable=SC1090,SC1091
    source "${rvm_path}/scripts/rvm"
  else
    # shellcheck disable=SC1090,SC1091
    source "$HOME/.rvm/scripts/rvm"
  fi
  command rvm "$@"
}

# Nodejs
use_node() {
  path_append "${1:-$PWD}node_modules/.bin"
}
