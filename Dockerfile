FROM debian:buster-slim

ARG USER_NAME="jovyan"
ARG USER_UID="1000"
ARG USER_GID="100"
ARG CONDA_URL="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"

ENV DEBIAN_FRONTEND=noninteractive \
  TERM=linux \
  SHELL=/bin/bash \
  USER_HOME=/home/$USER_NAME \
  XDG_CACHE_HOME=$USER_HOME/.cache/ \
  CONDA_DIR=/opt/conda

# Debugging the build
ARG DEBUG=false

USER root
ADD src/* /tmp/
WORKDIR /tmp/
RUN ./install.sh
WORKDIR $USER_HOME
USER $USER_UID

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["singleuser"]
