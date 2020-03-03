#!/usr/bin/env bash
set -e
export PATH=$CONDA_DIR/bin:$PATH
# Load the functions.sh
source functions.sh

banner 'Update OS packages'
apt-build apt-utils
apt-upgrade

banner 'OS package install'
# core packages
apt-install build-essential \
  apt-transport-https \
  ca-certificates \
  curl \
  rsync \
  netcat \
  bzip2 \
  ca-certificates \
  sudo \
  locales \
  fonts-liberation
gen-locales

# Git
apt-install git

banner 'Conda Install'
# update
install-conda
pip-install -U pip \
  setuptools \
  wheel \
  cython

banner 'Setup User'
# general env settings
cmd sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
  cmd echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
  cmd sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
  cmd echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook && \
  chmod g+w /etc/passwd

# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
banner 'JupyterLab install'
conda-install notebook jupyterhub 'jupyterlab<2.0.0' && \
  cmd rm -rf /root/.jupyter && \
  cmd mkdir -p /root/.jupyter && \
  cmd ln -s /opt/conda/etc/jupyter /root/.jupyter && \
  cmd rm -rf /root/.local/share/jupyter && \
  cmd mkdir -p /root/.local/share/jupyter && \
  cmd ln -s /opt/conda/share/jupyter /root/.local/share/jupyter


banner 'Install nb_conda'
conda-install  nb_conda
jupyter-notebook-install nb_conda --symlink
jupyter-notebook-enable nb_conda
jupyter-server-enable nb_conda


banner 'JupyterHub Cluster install'
conda-install ipyparallel
cmd ipcluster nbextension enable

# https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile
banner 'JupyterLab ScyPy install'
# ffmpeg for matplotlib anim
apt-install ffmpeg
conda-install beautifulsoup4 \
    'conda-forge::blas=*=openblas' \
    bokeh \
    cloudpickle \
    cython \
    dask \
    dill \
    h5py \
    hdf5 \
    ipywidgets \
    matplotlib-base \
    numba \
    numexpr \
    pandas \
    patsy \
    protobuf \
    scikit-image \
    scikit-learn \
    scipy \
    seaborn \
    sqlalchemy \
    statsmodels \
    sympy \
    vincent \
    xlrd
jupyter-notebook-enable widgetsnbextension


banner 'JupyterLab Jupyter Widgets install'
# https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
jupyter-lab-install @jupyter-widgets/jupyterlab-manager


#banner 'JupyterLab jupyterlab_bokeh install'
# https://github.com/bokeh/jupyter_bokeh
#jupyter-lab-install jupyterlab_bokeh


banner 'JupyterLab facets install'
cmd git clone https://github.com/PAIR-code/facets.git  && \
  cd facets && \
  jupyter-notebook-install facets-dist/ && \
  cd .. || exit 1


banner 'JupyterLab IPython SQL Magic install'
conda-install mysqlclient psycopg2 pymssql ipython-sql


banner 'JupyterLab Browser Notifications Magic install'
# https://github.com/ShopRunner/jupyter-notify
pip-install jupyternotify


banner 'JupyterLab Callgraph Magic install'
# https://github.com/ShopRunner/jupyter-notify
pip-install callgraph


banner 'JupyterLab jupyterlab-sql install'
# https://github.com/pbugnion/jupyterlab-sql
pip-install jupyterlab_sql && \
  jupyter-server-enable jupyterlab_sql


banner 'JupyterLab debug install'
# https://github.com/jupyterlab/debugger
conda-install xeus-python notebook ptvsd && \
  jupyter-lab-install @jupyterlab/debugger


banner 'JupyterLab jupyter-archive install'
# https://github.com/hadim/jupyter-archive/
conda-install jupyter-archive


banner 'JupyterLab metadata/dataregistry install'
# https://github.com/jupyterlab/jupyterlab-metadata-service
jupyter-lab-install @jupyterlab/metadata-extension @jupyterlab/dataregistry-extension


#banner 'JupyterLab celltags install'
# https://github.com/jupyterlab/jupyterlab-celltags
#jupyter-lab-install @jupyterlab/celltags


banner 'JupyterLab geojson install'
# https://github.com/jupyterlab/jupyter-renderers/tree/master/packages/geojson-extension
jupyter-lab-install @jupyterlab/geojson-extension


banner 'JupyterLab commenting install'
# https://github.com/jupyterlab/jupyterlab-commenting
jupyter-lab-install @jupyterlab/commenting-extension


banner 'JupyterLab ViewSCAD install'
# https://github.com/nickc92/ViewSCAD
apt-install openscad && \
  pip-install viewscad


banner 'JupyterLab K3D install'
conda-install k3d && \
  jupyter-lab-install k3d


banner 'JupyterLab plotly install'
# https://github.com/plotly/plotly.py
apt-install libgtk2.0-0 libgconf-2-4 xvfb xauth fuse desktop-file-utils chromium && \
  conda-install -c plotly plotly && \
  conda-install -c plotly plotly-orca && \
  conda-install -c plotly plotly-geo && \
  conda-install openssl psutil requests ipywidgets && \
  jupyter-lab-install jupyterlab-plotly && \
  jupyter-lab-install plotlywidget && \
  (set -xe; python3 -c 'import plotly.io as pio;pio.orca.config.use_xvfb = True;pio.orca.config.save();')
#jupyter-lab-install jupyterlab-chart-editor


banner 'JupyterLab Celltests install'
# https://github.com/timkpaine/jupyterlab_celltests
# https://github.com/computationalmodelling/nbval
jupyter-lab-install jupyterlab_celltests


banner 'JupyterLab variableinspector install'
# https://github.com/lckr/jupyterlab-variableInspector
jupyter-lab-install @lckr/jupyterlab_variableinspector


banner 'JupyterLab spellchecker install'
# https://github.com/ijmbarr/jupyterlab_spellchecker
jupyter-lab-install @ijmbarr/jupyterlab_spellchecker


banner 'JupyterLab Language Server Protocol install'
# https://github.com/krassowski/jupyterlab-lsp
pip-install jupyter-lsp && \
  conda-install python-language-server && \
  jupyter-lab-install @krassowski/jupyterlab-lsp


banner 'JupyterLab Code Formatter install'
# https://github.com/ryantam626/jupyterlab_code_formatter
conda-install black && \
  jupyter-lab-install @ryantam626/jupyterlab_code_formatter && \
  conda-install jupyterlab_code_formatter && \
  jupyter-server-enable jupyterlab_code_formatter


banner 'JupyterLab Go to definition install'
# https://github.com/krassowski/jupyterlab-go-to-definition
jupyter-lab-install @krassowski/jupyterlab_go_to_definition


banner 'JupyterLab Run all install'
# https://github.com/wallneradam/jupyterlab-run-all-buttons
jupyter-lab-install @wallneradam/run_all_buttons


banner 'JupyterLab flake8 install'
# https://github.com/mlshapiro/jupyterlab-flake8
conda-install flake8
jupyter-lab-install jupyterlab-flake8


banner 'JupyterLab filetree install'
# https://github.com/youngthejames/jupyterlab_filetree
jupyter-lab-install jupyterlab_filetree


banner 'JupyterLab python-file install'
# https://github.com/jtpio/jupyterlab-python-file
jupyter-lab-install jupyterlab-python-file


banner 'JupyterLab Spreadsheet install'
# https://github.com/quigleyj97/jupyterlab-spreadsheet
jupyter-lab-install jupyterlab-spreadsheet


banner 'JupyterLab s3-browser install'
# https://github.com/IBM/jupyterlab-s3-browser
pip-install jupyterlab-s3-browser && \
  jupyter-lab-install jupyterlab-s3-browser && \
  jupyter-server-enable jupyterlab_s3_browser


banner 'jupyter Kernel (beakerx) install'
# http://beakerx.com/
conda-install ipywidgets beakerx


banner 'jupyter Kernel (xeus-cling C++) install'
# https://github.com/jupyter-xeus/xeus-cling
conda-install xeus-cling xtensor xtensor-blas


#banner 'jupyter Kernel (JS/TS) install'
# https://github.com/yunabe/tslab
#  cmd npm install tslab && \
#  cmd tslab install --python=python3


#banner 'jupyter Kernel (R) install'
# apt-install fonts-dejavu unixodbc unixodbc-dev r-cran-rodbc gfortran gcc \
# && cmd ln -s /bin/tar /bin/gtar \
# && conda-install r-base r-caret r-crayon r-devtools r-forecast r-hexbin r-htmltools r-htmlwidgets r-irkernel r-nycflights13 r-plyr r-randomforest r-rcurl r-reshape2 r-rmarkdown r-rodbc r-rsqlite r-shiny r-tidyverse unixodbc r-e1071


banner 'jupyter Kernel (Ruby) install'
# https://github.com/SciRuby/iruby
apt-install libtool libffi-dev ruby ruby-dev make && \
  apt-install libzmq3-dev libczmq-dev && \
  cmd gem install ffi-rzmq && \
  cmd gem install iruby --pre && \
  cmd iruby register --force


banner 'jupyter Kernel (.Net) install'
# https://devblogs.microsoft.com/dotnet/net-core-with-juypter-notebooks-is-here-preview-1/
apt-install gnupg curl && \
  curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
  cmd curl -s https://packages.microsoft.com/config/debian/9/prod.list -o /etc/apt/sources.list.d/microsoft-prod.list && \
  apt-update && \
  apt-install dotnet-sdk-3.1 && \
  cmd dotnet tool install -g dotnet-try && \
  cmd /root/.dotnet/tools/dotnet-try jupyter install


# PHP
# https://github.com/Litipk/Jupyter-PHP

# Go
# https://github.com/yunabe/lgo

# Jupyter kernel for the GraalVM (python, js, ruby, R)
# https://github.com/hpi-swa/ipolyglot


is-debug || (banner 'JupyterLab Building' && jupyter-lab-build)

banner 'Conda fix permissions' && fix-conda-permissions

banner 'Cleanup' && conda-clean && conda-cache-clean && apt-clean

banner 'Setup JupyterHub'
  pip-install jinja2 click && \
  cmd cp -r /tmp/templates /root/ && \
  cmd cp /tmp/functions.sh /root/ && \
  cmd cp /tmp/render-templates.py /usr/bin/render-templates && \
  cmd cp /tmp/docker-entrypoint.sh /

#banner 'Installing Apache Airflow'
#apt-build freetds-dev libkrb5-dev libsasl2-dev libssl-dev libffi-dev libpq-dev
#apt-install freetds-bin default-libmysqlclient-dev libsasl2-dev
#pip-install 'redis==3.2'
#pip-install apache-airflow[all]

#banner 'JupyterLab running Tests'
#conda_install nbval
#nbtest $HOME/work/examples/*.ipynb
