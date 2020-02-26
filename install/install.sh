#!/bin/bash
set -e
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

header 'JupyterLab jupyterlab-manager install'
# https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
jupyter_install @jupyter-widgets/jupyterlab-manager

header 'JupyterLab jupyterlab-git install'
# https://github.com/jupyterlab/jupyterlab-git
jupyter_install @jupyterlab/git

header 'JupyterLab jupyterlab-debugger install'
# https://github.com/jupyterlab/debugger
conda_install 'xeus-python=>0.6.7' 'notebook>=6' ptvsd
jupyter_install @jupyterlab/debugger

header 'JupyterLab jupyterlab_templates install'
# https://github.com/timkpaine/jupyterlab_templates
pip_install jupyterlab_templates
jupyter_install jupyterlab_templates
jupyter_enable jupyterlab_templates

header 'JupyterLab jupyter-archive install'
# https://github.com/hadim/jupyter-archive/
conda_install jupyter-archive
jupyter_enable jupyter_archive

header 'JupyterLab jupyterlab-toc install'
# https://github.com/jupyterlab/jupyterlab-toc
jupyter_install @jupyterlab/toc

header 'JupyterLab jupyterlab-shortcutui install'
# https://github.com/jupyterlab/jupyterlab-shortcutui
jupyter_install @jupyterlab/shortcutui

header 'JupyterLab jupyterlab-latex install'
# https://github.com/jupyterlab/jupyterlab-latex
apt_install texlive-xetex # texlive-full texlive-extra-utils
pip_install jupyterlab_latex
jupyter_install @jupyterlab/latex
jupyter_enable jupyterlab_latex

header 'JupyterLab jupyterlab-data-explorer install'
# https://github.com/jupyterlab/jupyterlab-metadata-service
# https://github.com/jupyterlab/jupyterlab-data-explorer
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

header 'JupyterLab jupyterlab-hdf5 install'
# https://github.com/jupyterlab/jupyterlab-hdf5
pip_install jupyterlab_hdf
jupyter_install @jupyterlab/hdf5


header 'JupyterLab plotly install'
# https://github.com/plotly/plotly.py
apt_install libgtk2.0-0 libgconf-2-4 chromium-browser fonts-liberation xvfb poppler-utils inkscape
conda_install -c plotly plotly
conda_install -c plotly plotly-orca
conda_install -c plotly plotly-geo
conda_install openssl psutil requests 'ipywidgets>=7.5'
jupyter_install jupyterlab-plotly
jupyter_install plotlywidget

header 'JupyterLab drawio install'
# https://github.com/QuantStack/jupyterlab-drawio
jupyter_install jupyterlab-drawio

header 'JupyterLab ViewSCAD install'
# https://github.com/nickc92/ViewSCAD
apt_add_repository ppa:openscad/releases
apt_install openscad
pip_install viewscad

header 'JupyterLab K3D install'
# https://github.com/K3D-tools/K3D-jupyter
conda_install k3d
jupyter_install k3d

header 'JupyterLab Celltests install'
# https://github.com/timkpaine/jupyterlab_celltests
# https://github.com/computationalmodelling/nbval
jupyter_install jupyterlab_celltests

header 'JupyterLab Kernel (SSH Kernel) install'
# https://github.com/NII-cloud-operation/sshkernel
pip_install sshkernel
python_bin -m sshkernel install --sys-prefix

header 'JupyterLab Kernel (xeus-cling C++) install'
# https://github.com/jupyter-xeus/xeus-cling
conda_install xeus-cling xtensor xtensor-blas -c conda-forge

header 'JupyterLab Kernel (ZSH) install'
# https://github.com/danylo-dubinin/zsh-jupyter-kernel
apt_install zsh
pip_install zsh_jupyter_kernel
python_bin -m zsh_jupyter_kernel.install --sys-prefix

header 'JupyterLab Kernel (Bash) install'
# https://github.com/takluyver/bash_kernel
pip_install bash_kernel
python_bin -m bash_kernel.install --sys-prefix

# PHP
# https://github.com/Litipk/Jupyter-PHP

# Go
# https://github.com/yunabe/lgo

# Jupyter kernel for the GraalVM (python, js, ruby, R)
# https://github.com/hpi-swa/ipolyglot

# Java
# https://github.com/scijava/scijava-jupyter-kernel
# https://github.com/SpencerPark/IJava

is_debug || (header 'JupyterLab Building all' && jupyter_build)
header 'JupyterLab extension install done'

header 'Installing Apache Airflow'
apt_build freetds-dev libkrb5-dev libsasl2-dev libssl-dev libffi-dev libpq-dev
apt_install libmysqlclient-dev libsasl2-dev
apt_install python3-ndg-httpsclient python3-pyasn1 python3-redis
pip_install apache-airflow[all]

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
