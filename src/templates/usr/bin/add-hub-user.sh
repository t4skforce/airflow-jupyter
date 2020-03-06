#!/usr/bin/env bash
set -e
USERNAME=$1
useradd --groups conda --shell {{env.SHELL|default('/bin/bash',true)}} --create-home --home "/home/$USERNAME" $USERNAME && \
mkdir -p "/home/$USERNAME/work" && \
(cd "/home/$USERNAME/work" && git init) && \
render-templates /root/templates/.home/ /home/$USERNAME/ && \
chown -R $USERNAME:conda "/home/$USERNAME"
