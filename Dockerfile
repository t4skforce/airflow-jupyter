FROM jupyter/scipy-notebook:latest

ARG DEBUG=false

USER root
# Install JupyterLab extensions
ADD install/*.sh /tmp/
ADD examples/*.* /home/$NB_USER/work/examples/
RUN /tmp/install.sh
USER $NB_UID
