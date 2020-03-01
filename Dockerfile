FROM debian:buster-slim

ARG CONDA_URL="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"

ENV USER_NAME="admin" \
  USER_UID="1000" \
  USER_GID="100" \
  CONDA_DIR=/opt/conda \
  CONFIG_PATH=/config

ENV DEBIAN_FRONTEND=noninteractive \
  TERM=linux \
  SHELL=/bin/bash \
  PATH=$CONDA_DIR/bin:$PATH \
  HUB_IP='0.0.0.0' \
  HUB_PORT=8000

# Debugging the build
ARG DEBUG=false

USER root
ADD src /tmp/
WORKDIR /tmp/
RUN ./install.sh

WORKDIR /root
VOLUME ["/config","/home"]
EXPOSE 8000
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["jupyterhub","--config=/config/hub/jupyterhub_config.py"]
