#!/bin/bash
# Load the functions.sh
. /tmp/functions.sh

header 'Update OS packages'
apt_upgrade

header 'OS package install'
apt_build apt-utils
# tools for workflows
apt_install curl rsync netcat
# pip
apt_install python3-setuptools python3-pip python3-openssl
# Git
apt_install git


header 'Conda update'
conda_update

header 'JupyterLab IPython SQL Magic install'
apt_install python3-mysqldb python3-psycopg2 python3-pymssql
pip_install ipython-sql

header 'JupyterLab jupyterlab-sql install'
# https://github.com/pbugnion/jupyterlab-sql
pip_install jupyterlab_sql
jupyter_enable jupyterlab_sql

header 'JupyterLab Jupyter Widgets install'
# https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
jupyter_install @jupyter-widgets/jupyterlab-manager

header 'JupyterLab git install'
# https://github.com/jupyterlab/jupyterlab-git
jupyter_install @jupyterlab/git

header 'JupyterLab debug install'
# https://github.com/jupyterlab/debugger
conda_install 'xeus-python=>0.6.7' 'notebook>=6' ptvsd
jupyter_install @jupyterlab/debugger

header 'JupyterLab jupyter-archive install'
# https://github.com/hadim/jupyter-archive/
conda_install jupyter-archive

header 'JupyterLab latex install'
# https://github.com/jupyterlab/jupyterlab-latex
apt_install texlive-full texlive-extra-utils texlive-xetex
jupyter_install @jupyterlab/latex

header 'JupyterLab metadata/dataregistry install'
# https://github.com/jupyterlab/jupyterlab-metadata-service
jupyter_install @jupyterlab/metadata-extension @jupyterlab/dataregistry-extension

header 'JupyterLab celltags install'
# https://github.com/jupyterlab/jupyterlab-celltags
jupyter_install @jupyterlab/celltags

header 'JupyterLab geojson install'
# https://github.com/jupyterlab/jupyter-renderers/tree/master/packages/geojson-extension
jupyter_install @jupyterlab/geojson-extension

header 'JupyterLab fasta install'
# https://github.com/jupyterlab/jupyter-renderers/tree/master/packages/fasta-extension
jupyter_install @jupyterlab/fasta-extension

header 'JupyterLab commenting install'
# https://github.com/jupyterlab/jupyterlab-commenting
jupyter_install @jupyterlab/commenting-extension

header 'JupyterLab drawio install'
# https://github.com/QuantStack/jupyterlab-drawio
jupyter_install jupyterlab-drawio

header 'JupyterLab ViewSCAD install'
apt_add_repository ppa:openscad/releases
apt_install openscad
pip_install viewscad

header 'JupyterLab Celltests install'
# https://github.com/timkpaine/jupyterlab_celltests
# https://github.com/computationalmodelling/nbval
jupyter_install jupyterlab_celltests

header 'JupyterLab Kernel (SSH Kernel) install'
# https://github.com/NII-cloud-operation/sshkernel
pip_install sshkernel

header 'JupyterLab Kernel (xeus-cling C++) install'
# https://github.com/jupyter-xeus/xeus-cling
conda_install xeus-cling

header 'JupyterLab Kernel (ZSH) install'
# https://github.com/danylo-dubinin/zsh-jupyter-kernel
apt_install zsh
pip_install zsh_jupyter_kernel
python_bin -m zsh_jupyter_kernel.install --sys-prefix

header 'JupyterLab Kernel (Bash) install'
# https://github.com/takluyver/bash_kernel
pip_install bash_kernel

# PHP
# https://github.com/Litipk/Jupyter-PHP

# Go
# https://github.com/yunabe/lgo

# Jupyter kernel for the GraalVM (python, js, ruby, R)
# https://github.com/hpi-swa/ipolyglot

# Java
# https://github.com/scijava/scijava-jupyter-kernel
# https://github.com/SpencerPark/IJava

header 'JupyterLab plotly install'
# https://github.com/plotly/plotly.py
conda_install -c plotly plotly
conda_install -c plotly plotly-orca
conda_install -c plotly plotly-geo
conda_install openssl psutil requests 'ipywidgets>=7.5'
jupyter_install jupyterlab-plotly
jupyter_install plotlywidget
jupyter_install jupyterlab-chart-editor

[ is_debug -neq $TRUE ] && header 'JupyterLab Building all' && jupyter_build
header 'JupyterLab extension install done'

header 'Installing Apache Airflow'
apt_build freetds-dev libkrb5-dev libsasl2-dev libssl-dev libffi-dev libpq-dev
apt_install libmysqlclient-dev libsasl2-dev
apt_install python3-ndg-httpsclient python3-pyasn1 python3-redis
pip_install apache-airflow[all]==${AIRFLOW_VERSION}

header 'Cleanup'
clean_all \
&& rm -rf \
       /var/lib/apt/lists/* \
       /tmp/* \
       /var/tmp/* \
       /usr/share/man \
       /usr/share/doc \
       /usr/share/doc-base \
       $CONDA_DIR/share/jupyter/lab/staging \
       /home/$NB_USER/.cache/yarn \
&& fix_permissions $NB_GID $CONDA_DIR \
&& fix_permissions $NB_GID /home/$NB_USER
