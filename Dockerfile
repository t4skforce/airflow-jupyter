FROM jupyter/scipy-notebook:latest

# Airflow
ARG AIRFLOW_VERSION=1.10.9
ARG DEBUG=false

USER root

# Install JupyterLab extensions
ADD install/*.sh /tmp/
RUN /tmp/install.sh

USER $NB_UID
