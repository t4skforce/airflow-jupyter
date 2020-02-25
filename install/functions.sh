#!/bin/bash
set -e
# set variables
declare -r TRUE=0
declare -r FALSE=1
declare -r PASSWD_FILE=/etc/passwd
declare APT_UPDATED=$FALSE
DEBUG=${DEBUG-'false'}
declare -a BUILD_DEPENDENCIES=${BUILD_DEPENDENCIES-()}

##################################################################
# Purpose: Converts a string to lower case
# Arguments:
#   $1 -> String to convert to lower case
##################################################################
function to_lower()
{
    local str="$@"
    local output
    output=$(tr '[A-Z]' '[a-z]'<<<"${str}")
    echo $output
}
##################################################################
# Purpose: Display an error message and die
# Arguments:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function die()
{
    local m="$1"	# message
    local e=${2-1}	# default exit status 1
    echo "$m"
    exit $e
}
##################################################################
# Purpose: Display an header message
# Arguments:
#   $1 -> Message
#   $2 -> length default:60 (optional)
##################################################################
function header()
{
  local l=${2-60}
  python -c 'import sys;print("\033[92m"+"\n".join(["#"*int(sys.argv[2]),"#"+str(sys.argv[1]).center(int(sys.argv[2])-2," ")+"#","#"*int(sys.argv[2])])+"\033[0m",file=sys.stderr)' "$1" "$l"
}
##################################################################
# Purpose: Return true if script is executed by the root user
# Arguments: none
# Return: True or False
##################################################################
function is_root()
{
   [ $(id -u) -eq 0 ] && return $TRUE || return $FALSE
}

##################################################################
# Purpose: Return true $user exits in /etc/passwd
# Arguments: $1 (username) -> Username to check in /etc/passwd
# Return: True or False
##################################################################
function is_user_exits()
{
    local u="$1"
    grep -q "^${u}" $PASSWD_FILE && return $TRUE || return $FALSE
}
##################################################################
# Purpose: check if apt-get update was wriggered
##################################################################
function is_apt_updated()
{
  return $APT_UPDATED
}
##################################################################
# Purpose: check if a binary is installed
# Arguments: $1 (binaryname)
# Return: True or False
##################################################################
function is_installed()
{
  hash add-apt-repository 2>/dev/null && return $TRUE || return $FALSE
}
##################################################################
# Purpose: check if debug is enabled
# Return: True or False
##################################################################
function is_debug()
{
  [ "$DEBUG" = "true" ] && return $TRUE || return $FALSE
}
##################################################################
# Purpose:
# set permissions on a directory
# after any installation, if a directory needs to be (human) user-writable,
# run this script on it.
# It will make everything in the directory owned by the group $NB_GID
# and writable by that group.
# Deployments that want to set a specific user id can preserve permissions
# by adding the `--group-add users` line to `docker run`.

# uses find to avoid touching files that already have the right permissions,
# which would cause massive image explosion

# right permissions are:
# group=$NB_GID
# AND permissions include group rwX (directory-execute)
# AND directories have setuid,setgid bits set
##################################################################
function fix_permissions()
{
  local GID="$1"
  shift # skip first
  for d in "$@"; do
    find "$d" \
      ! \( \
        -group $GID \
        -a -perm -g+rwX  \
      \) \
      -exec chgrp $GID {} \; \
      -exec chmod g+rwX {} \;
    # setuid,setgid *on directories only*
    find "$d" \
      \( \
          -type d \
          -a ! -perm -6000  \
      \) \
      -exec chmod +6000 {} \;
  done
}
##################################################################
# Purpose: Remove *.pyc|*.pyo from folder
# Arguments:
#   $1 -> Folder location default:'.' (optional)
##################################################################
function pyclean()
{
  local PATH=${1:-.}
  (set -x; /usr/bin/find "$1" -regex '^.*\(__pycache__\|\.py[co]\)$' -delete)
}
##################################################################
# Purpose: apt-get update
##################################################################
function apt_update()
{
  is_debug \
  && (set -x; apt-get update -yqq) \
  || (set -x; apt-get update -yqq >/dev/null)
  APT_UPDATED=$TRUE
}
##################################################################
# Purpose: apt-get upgrade
##################################################################
function apt_upgrade()
{
  is_apt_updated || apt_update
  is_debug \
  && (set -x; apt-get upgrade -yqq) \
  || (set -x; apt-get upgrade -yqq >/dev/null)
}
##################################################################
# Purpose: apt-get install
# Arguments:
#   $@ -> packages to be installed
##################################################################
function apt_install()
{
  is_apt_updated || apt_update
  is_debug \
  && (set -x; apt-get install -yq --no-install-recommends $@) \
  || (set -x; apt-get install -yq --no-install-recommends $@ >/dev/null)
}
##################################################################
# Purpose: apt-get install
# Arguments:
#   $@ -> packages to be installed
##################################################################
function apt_build()
{
  BUILD_DEPENDENCIES=($@ "${BUILD_DEPENDENCIES[@]}")
  apt_install $@
}
##################################################################
# Purpose: add-apt-repository
# Arguments:
#   $@ -> repository to be added
##################################################################
function apt_add_repository(){
  is_installed add-apt-repository || apt_install software-properties-common
  is_debug \
  && (set -x; add-apt-repository -y $@) \
  || (set -x; add-apt-repository -y $@ >/dev/null)
  apt_update
}
##################################################################
# Purpose: python3
# Arguments:
#   $@ -> arguments for python
##################################################################
function python_bin()
{
  local bin=$(is_installed python3 && echo 'python3' || echo 'python')
  is_debug \
  && (set -x; $bin $@) \
  || (set -x; $bin $@ >/dev/null)
}
##################################################################
# Purpose: pip
# Arguments:
#   $@ -> commands for pip
##################################################################
function python_pip()
{
  python_bin -m pip $@
}
##################################################################
# Purpose: pip install
# Arguments:
#   $@ -> packages to install
##################################################################
function pip_install()
{
  python_pip install --no-cache-dir $@
}
##################################################################
# Purpose: conda
# Arguments:
#   $@ -> arguments for conda
##################################################################
function conda_bin()
{
  is_debug \
  && (set -x; conda $@) \
  || (set -x; conda $@ >/dev/null)
}
##################################################################
# Purpose: conda install
# Arguments:
#   $@ -> packages to install
##################################################################
function conda_install()
{
  conda_bin install --quiet --yes $@
}
##################################################################
# Purpose: conda update
##################################################################
function conda_update()
{
  conda_bin  update -y --all
  conda_bin  update -y -n base conda
}
##################################################################
# Purpose: jupyter labextension install
# Arguments:
#   $@ -> extensions to install
##################################################################
function jupyter_install()
{
  export NODE_OPTIONS=--max-old-space-size=4096
  is_debug \
  && (set -x; jupyter labextension install $@ || (cat /tmp/jupyterlab-debug-*.log && exit 1)) \
  || (set -x; jupyter labextension install $@ --no-build >/dev/null || (cat /tmp/jupyterlab-debug-*.log && exit 1))
  unset NODE_OPTIONS
}
##################################################################
# Purpose: jupyter serverextension enable
# Arguments:
#   $@ -> extensions to enable
##################################################################
function jupyter_enable()
{
  if is_debug -eq $TRUE; then
    (set -x; jupyter serverextension enable $@ --py --sys-prefix || (cat /tmp/jupyterlab-debug-*.log && exit 1)) && jupyter_build
  else
    (set -x; jupyter serverextension enable $@ --py --sys-prefix >/dev/null || (cat /tmp/jupyterlab-debug-*.log && exit 1))
  fi
}
##################################################################
# Purpose: jupyter lab build
##################################################################
function jupyter_build()
{
  export NODE_OPTIONS=--max-old-space-size=4096
  is_debug \
  && (set -x; jupyter lab build || (cat /tmp/jupyterlab-debug-*.log && exit 1)) \
  || (set -x; jupyter lab build >/dev/null || (cat /tmp/jupyterlab-debug-*.log && exit 1))
  unset NODE_OPTIONS
}
##################################################################
# Purpose: conda clean
##################################################################
function clean_conda()
{
  is_debug \
  && (set -x; conda clean --all -f -y) \
  || (set -x; conda clean --all -f -y >/dev/null)
}
##################################################################
# Purpose: npm cache clean
##################################################################
function clean_npm_cache()
{
  is_debug \
  && (set -x; npm cache clean --force) \
  || (set -x; npm cache clean --force >/dev/null)
}
##################################################################
# Purpose: apt-get autoremove
##################################################################
function clean_apt()
{
  is_debug \
  && (set -x; apt-get autoremove -yqq --purge "${BUILD_DEPENDENCIES[@]}" $@) \
  || (set -x; apt-get autoremove -yqq --purge "${BUILD_DEPENDENCIES[@]}" $@ >/dev/null)
  is_debug \
  && (set -x; apt-get clean) \
  || (set -x; apt-get clean >/dev/null)
}
##################################################################
# Purpose: clean all
##################################################################
function clean_all()
{
  clean_conda \
  && pyclean / \
  && clean_npm_cache \
  && clean_apt $@ \
  && return $TRUE || return $FALSE
}
