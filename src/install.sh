#!/bin/bash
# expand PATH
echo "PATH=$CONDA_DIR/bin:\$PATH" >> /etc/environment
source /etc/environment && export PATH

# Load the functions.sh
source functions.sh

banner 'Update OS packages'
apt-build apt-utils
apt-upgrade

banner 'OS package install'
# core packages
apt-install build-essential \
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
  cmd sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc \
  && cmd echo "auth requisite pam_deny.so" >> /etc/pam.d/su \
  && cmd sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers \
  && sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers \
  && add-user --create-home --shell ${SHELL} --uid ${USER_UID} --gid ${USER_GID} --home ${USER_HOME} ${USER_NAME} \
  && chmod g+w /etc/passwd

# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
banner 'JupyterLab install'
conda-install notebook jupyterhub jupyterlab

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


banner 'JupyterLab jupyterlab_bokeh install'
jupyter-lab-install jupyterlab_bokeh


banner 'JupyterLab facets install'
cmd git clone https://github.com/PAIR-code/facets.git \
  && cd facets \
  && jupyter-notebook-install facets-dist/ \
  && cd .. || exit 1

banner 'matplotlib build font cache'
MPLBACKEND=Agg python3 -c "import matplotlib.pyplot"

banner 'JupyterLab IPython SQL Magic install'
conda-install mysqlclient psycopg2 pymssql ipython-sql


banner 'JupyterLab jupyterlab-sql install'
# https://github.com/pbugnion/jupyterlab-sql
pip-install jupyterlab_sql
jupyter-server-enable jupyterlab_sql


banner 'JupyterLab git install'
# https://github.com/jupyterlab/jupyterlab-git
jupyter-lab-install @jupyterlab/git


banner 'JupyterLab debug install'
# https://github.com/jupyterlab/debugger
conda-install xeus-python notebook ptvsd
jupyter-lab-install @jupyterlab/debugger


banner 'JupyterLab jupyter-archive install'
# https://github.com/hadim/jupyter-archive/
conda-install jupyter-archive


banner 'JupyterLab latex install'
# https://github.com/jupyterlab/jupyterlab-latex
apt-install texlive-xetex # texlive-full texlive-extra-utils
jupyter-lab-install @jupyterlab/latex


banner 'JupyterLab metadata/dataregistry install'
# https://github.com/jupyterlab/jupyterlab-metadata-service
jupyter-lab-install @jupyterlab/metadata-extension @jupyterlab/dataregistry-extension


banner 'JupyterLab celltags install'
# https://github.com/jupyterlab/jupyterlab-celltags
jupyter-lab-install @jupyterlab/celltags


banner 'JupyterLab geojson install'
# https://github.com/jupyterlab/jupyter-renderers/tree/master/packages/geojson-extension
jupyter-lab-install @jupyterlab/geojson-extension


banner 'JupyterLab fasta install'
# https://github.com/jupyterlab/jupyter-renderers/tree/master/packages/fasta-extension
jupyter-lab-install @jupyterlab/fasta-extension


banner 'JupyterLab commenting install'
# https://github.com/jupyterlab/jupyterlab-commenting
jupyter-lab-install @jupyterlab/commenting-extension


banner 'JupyterLab drawio install'
# https://github.com/QuantStack/jupyterlab-drawio
jupyter-lab-install jupyterlab-drawio


banner 'JupyterLab ViewSCAD install'
# https://github.com/nickc92/ViewSCAD
apt-install openscad
pip-install viewscad


banner 'JupyterLab Celltests install'
# https://github.com/timkpaine/jupyterlab_celltests
# https://github.com/computationalmodelling/nbval
jupyter-lab-install jupyterlab_celltests


banner 'JupyterLab plotly install'
# https://github.com/plotly/plotly.py
conda-install -c plotly plotly
conda-install -c plotly plotly-orca
conda-install -c plotly plotly-geo
conda-install openssl psutil requests ipywidgets
jupyter-lab-install jupyterlab-plotly
jupyter-lab-install plotlywidget
#jupyter-lab-install jupyterlab-chart-editor


banner 'JupyterLab Kernel (SSH Kernel) install'
# https://github.com/NII-cloud-operation/sshkernel
pip-install sshkernel


banner 'JupyterLab Kernel (xeus-cling C++) install'
# https://github.com/jupyter-xeus/xeus-cling
conda-install xeus-cling


banner 'JupyterLab Kernel (ZSH) install'
# https://github.com/danylo-dubinin/zsh-jupyter-kernel
apt-install zsh
pip-install zsh_jupyter_kernel
python-install zsh_jupyter_kernel.install


banner 'JupyterLab Kernel (Bash) install'
# https://github.com/takluyver/bash_kernel
pip-install bash_kernel

# PHP
# https://github.com/Litipk/Jupyter-PHP

# Go
# https://github.com/yunabe/lgo

# Jupyter kernel for the GraalVM (python, js, ruby, R)
# https://github.com/hpi-swa/ipolyglot

# Java
# https://github.com/scijava/scijava-jupyter-kernel
# https://github.com/SpencerPark/IJava



is-debug || (banner 'JupyterLab Building' && jupyter-lab-build)


banner 'Installing Apache Airflow'
apt-build freetds-dev libkrb5-dev libsasl2-dev libssl-dev libffi-dev libpq-dev
apt-install freetds-bin default-libmysqlclient-dev libsasl2-dev
pip-install 'redis==3.2'
pip-install apache-airflow[all]

#banner 'JupyterLab running Tests'
#conda_install nbval
#nbtest $HOME/work/examples/*.ipynb

banner 'Setting up startup environment'
# https://medium.com/better-programming/running-a-container-with-a-non-root-user-e35830d1f42a
apt-install gosu
conda-install jinja2 click
cmd mv ./render-template.py /usr/sbin/render-template

banner 'Cleanup'
fix-permissions $USER_GID $CONDA_DIR \
&& fix-permissions $USER_GID $USER_HOME
#clean_all \
#&& rm -rf \
#       /var/lib/apt/lists/* \
#       /tmp/* \
#       /var/tmp/* \
#       /usr/share/man \
#       /usr/share/doc \
#       /usr/share/doc-base \
#       $CONDA_DIR/share/jupyter/lab/staging \
#       $HOME/.cache/yarn \
#&& fix-permissions $USER_GID $CONDA_DIR \
#&& fix-permissions $USER_GID /home/$HOME
