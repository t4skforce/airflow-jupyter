#!/usr/bin/env bash
set -e
source /root/functions.sh

render-templates

# setup admin user
user-exits ${USER_NAME} || useradd-hub ${USER_NAME} && \
(USER_PASS=${USER_PASS-$(randpw)} && echo "${USER_NAME}:${USER_PASS}" | chpasswd && banner "Username: '$USER_NAME' Password: '$USER_PASS'")

exec "$@"
