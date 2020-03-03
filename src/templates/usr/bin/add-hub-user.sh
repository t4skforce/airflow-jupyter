#!/usr/bin/env bash
set -e
USERNAME=$1
adduser --create-home -q --gecos "" --shell {{env.SHELL|default('/bin/bash',true)}} --groups conda --home "/home/$USERNAME" --disabled-password && \
mkdir -p "/home/$USERNAME/work" && \
chown -R $USERNAME:conda "/home/$USERNAME/work"
