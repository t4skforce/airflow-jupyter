#!/bin/bash
set -e
# set variables
declare SELF_DIRECTORY=$(cd `dirname $0` && pwd)
declare TRUE=0
declare FALSE=1
declare PASSWD_FILE=/etc/passwd
declare APT_UPDATED=$FALSE
DEBUG=${DEBUG-'false'}
declare -a BUILD_DEPENDENCIES=${BUILD_DEPENDENCIES-()}

##################################################################
# Purpose: Converts a string to lower case
# Arguments:
#   $1 -> String to convert to lower case
##################################################################
function to-lower()
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
function banner()
{
  local SIZE=${2-60}
  local text=${1-'Sample Text'}
  local str=$(printf "%*s" $(( ($SIZE - 4 - ${#text}) / 2)) "" && printf "%s" "$text" && printf "%*s" $(( ($SIZE - 4 - ${#text}) / 2)) "")
  local len=$((${#str}+4))
  tput setaf 2 && \
  (for i in $(seq $len); do echo -n '#'; done) && echo && \
  echo "# $str #" && \
  (for i in $(seq $len); do echo -n '#'; done) && echo && \
  tput sgr0 && sleep .1 && return $TRUE || return $FALSE
}
##################################################################
# Purpose: Return true if script is executed by the root user
# Arguments: none
# Return: True or False
##################################################################
function is-root()
{
   [ $(id -u) -eq 0 ] && return $TRUE || return $FALSE
}
##################################################################
# Purpose: Return true $user exits in /etc/passwd
# Arguments: $1 (username) -> Username to check in /etc/passwd
# Return: True or False
##################################################################
function user-exits()
{
    is-root || die 'can only be executed as root'
    local u="$1"
    grep -q "^${u}" $PASSWD_FILE && return $TRUE || return $FALSE
}
##################################################################
# Purpose: add user to system
# Environment:
#   $SHELL -> logon shell
#   $USER_UID -> user id
#   $USER_GID -> group id
#   $USER_NAME -> username
# Return: True or False
##################################################################
function add-user()
{
  is-root || die 'can only be executed as root'
  add-user --create-home --shell ${SHELL} --uid ${USER_UID} --gid ${USER_GID} --groups sudo --home "/home/${USER_NAME}" ${USER_NAME} \
  && echo "${USER_NAME}:${USER_NAME}" | chpasswd \
  && cmd chown -R ${USER_NAME} "/home/${USER_NAME}" \
  && cmd cp -r /etc/skel/. "/home/${USER_NAME}"
  return $?
}
##################################################################
# Purpose: update exsisint user uid and gid
##################################################################
function update-user()
{
  is-root || die 'can only be executed as root'
  local OUID=$(id -u ${USER_NAME})
  local OGID=$(id -g ${USER_NAME})
  [ "$OUID" != "$USER_UID" ] && cmd usermod -u $USER_UID $USER_NAME && find / -user $OUID -exec chown -h $USER_NAME {} \;
  [ "$OGID" != "$USER_GID" ] && cmd groupmod -g $USER_GID $USER_NAME && find / -group $OGID -exec chgrp -h $USER_GID {} \;
}
##################################################################
# Purpose: check if apt-get update was wriggered
##################################################################
function is-apt-updated()
{
  return $APT_UPDATED
}
##################################################################
# Purpose: check if a binary is installed
# Arguments: $1 (binaryname)
# Return: True or False
##################################################################
function is-installed()
{
  hash $1 2>/dev/null && return $TRUE || return $FALSE
}
##################################################################
# Purpose: check if debug is enabled
# Return: True or False
##################################################################
function is-debug()
{
  [ "$DEBUG" = "true" ] && return $TRUE || return $FALSE
}
##################################################################
# Purpose: run any command silten or with debug output
# Arguments:
#   $@ -> command to run
##################################################################
function cmd()
{
  is-debug && (set -xe; $@) || (set -xe; $@ >/dev/null)
  return $?
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
function fix-permissions()
{
  is-root || die 'can only be executed as root'
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
# Purpose: generate locales
##################################################################
function gen-locales()
{
  is-root || die 'can only be executed as root'
  cmd echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && cmd locale-gen
  return $?
}
##################################################################
# Purpose: run py.test against a notebook
# Arguments:
#   $@ -> py.test --nbval-lax $@
##################################################################
function nb-test()
{
  py.test --nbval $@
  return $?
}
##################################################################
# Purpose: add system user
##################################################################
function add-user()
{
  is-root || die 'can only be executed as root'
  cmd useradd $@
  return $?
}
##################################################################
# Purpose: add conda to the system
##################################################################
function install-conda()
{
  cmd curl $CONDA_URL --output conda.sh --silent \
  && cmd /bin/bash ./conda.sh -f -b -p "$CONDA_DIR" \
  && cmd ln -s "$CONDA_DIR/etc/profile.d/conda.sh" /etc/profile.d/conda.sh \
  && cmd echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/skel/.bashrc \
  && cmd echo "conda activate base" >> /etc/skel/.bashrc \
  && cmd echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc \
  && cmd echo "conda activate base" >> ~/.bashrc \
  && cmd conda config --system --prepend channels conda-forge \
  && cmd conda config --system --set auto_update_conda false \
  && cmd conda config --system --set show_channel_urls true \
  && cmd conda config --system --set always_yes true \
  && (set -xe; conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned) \
  && conda-install conda \
  && conda-install pip \
  && cmd conda update --all --quiet --yes || exit 1
  return $?
}
##################################################################
# Purpose: Remove *.pyc|*.pyo from folder
# Arguments:
#   $1 -> Folder location default:'.' (optional)
##################################################################
function python-clean()
{
  local DIR=${1:-.}
  cmd find "$DIR" -regex '^.*\(__pycache__\|\.py[co]\)$' -delete
  return $?
}
##################################################################
# Purpose: apt-get update
##################################################################
function apt-update()
{
  is-root || die 'can only be executed as root'
  cmd apt-get update -yqq
  local EXITCODE=$?
  APT_UPDATED=$TRUE
  return $EXITCODE
}
##################################################################
# Purpose: apt-get upgrade
##################################################################
function apt-upgrade()
{
  is-root || die 'can only be executed as root'
  is-apt-updated || apt-update
  cmd apt-get upgrade -yqq
  return $?
}
##################################################################
# Purpose: apt-get install
# Arguments:
#   $@ -> packages to be installed
##################################################################
function apt-install()
{
  is-root || die 'can only be executed as root'
  is-apt-updated || apt-update
  cmd apt-get install -yq --no-install-recommends $@
  return $?
}
##################################################################
# Purpose: apt-get install
# Arguments:
#   $@ -> packages to be installed
##################################################################
function apt-build()
{
  is-root || die 'can only be executed as root'
  BUILD_DEPENDENCIES=($@ "${BUILD_DEPENDENCIES[@]}")
  apt-install $@
  return $?
}
##################################################################
# Purpose: add-apt-repository
# Arguments:
#   $@ -> repository to be added
##################################################################
function apt-add-repository(){
  is-root || die 'can only be executed as root'
  is-installed add-apt-repository || apt-install software-properties-common
  cmd add-apt-repository -y $@ && apt-update
  return $?
}
##################################################################
# Purpose: pip
# Arguments:
#   $@ -> commands for pip
##################################################################
function python-pip()
{
  cmd python3 -m pip $@
  return $?
}
##################################################################
# Purpose: pip install
# Arguments:
#   $@ -> packages to install
##################################################################
function pip-install()
{
  python-pip install --no-cache-dir $@
  return $?
}
##################################################################
# Purpose: python3 -m $1 --sys-prefix
# Arguments:
#   $1 -> module to isntall
##################################################################
function python-install()
{
  cmd python3 -m $1 --sys-prefix
  return $?
}
##################################################################
# Purpose: conda install
# Arguments:
#   $@ -> packages to install
##################################################################
function conda-install()
{
  cmd conda install --quiet --yes $@
  return $?
}
##################################################################
# Purpose: conda update
##################################################################
function conda-update()
{
  cmd conda update -y --all && \
  cmd conda update -y -n base conda
  return $?
}
##################################################################
# Purpose: jupyter labextension install
# Arguments:
#   $@ -> extensions to install
##################################################################
function jupyter-lab-install()
{
  export NODE_OPTIONS=--max-old-space-size=16000
  cmd jupyter labextension install $@ --no-build || (cat /tmp/jupyterlab-debug-*.log && exit 1)
  local EXITCODE=$?
  is-debug && jupyter-lab-build
  unset NODE_OPTIONS
  return $EXITCODE
}
##################################################################
# Purpose: jupyter lab build
##################################################################
function jupyter-lab-build()
{
  export NODE_OPTIONS=--max-old-space-size=16000
  cmd jupyter lab build || (cat /tmp/jupyterlab-debug-*.log && exit 1)
  local EXITCODE=$?
  unset NODE_OPTIONS
  return $EXITCODE
}
##################################################################
# Purpose: jupyter serverextension enable
# Arguments:
#   $@ -> extensions to enable
##################################################################
function jupyter-server-enable()
{
  cmd jupyter serverextension enable $@ --py --sys-prefix
  return $?
}
##################################################################
# Purpose: jupyter nbextension enable
# Arguments:
#   $@ -> extensions to enable
##################################################################
function jupyter-notebook-install()
{
  cmd jupyter nbextension install $@ --sys-prefix
  return $?
}
##################################################################
# Purpose: jupyter nbextension enable
# Arguments:
#   $@ -> extensions to enable
##################################################################
function jupyter-notebook-enable()
{
  cmd jupyter nbextension enable --py $@ --sys-prefix
  return $?
}
##################################################################
# Purpose: conda clean
##################################################################
function conda-clean()
{
  cmd conda clean -tipsy
  return $?
}
##################################################################
# Purpose: npm cache clean
##################################################################
function conda-cache-clean()
{
  cmd npm cache clean --force
  return $?
}
##################################################################
# Purpose: apt-get autoremove
##################################################################
function apt-clean()
{
  cmd apt-get autoremove -yqq --purge "${BUILD_DEPENDENCIES[@]}" $@ && \
  cmd apt-get clean
  return $?
}
##################################################################
# Purpose: clean all
# Arguments:
#   $@ -> packages to be removed
##################################################################
function all-clean()
{
  conda-clean \
  && conda-cache-clean \
  && python-clean / \
  && apt-clean $@ \
  && return $TRUE || return $FALSE
}
