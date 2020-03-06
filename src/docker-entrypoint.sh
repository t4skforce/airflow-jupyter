#!/usr/bin/env bash
set -e
source /root/functions.sh

# setup admin user
user-exits ${USER_NAME} || add-hub-user.sh ${USER_NAME} && \
(USER_PASS=${USER_PASS-$(randpw)} && echo "${USER_NAME}:${USER_PASS}" | chpasswd && banner "Username: '$USER_NAME' Password: '$USER_PASS'")

render-templates

exec "$@"
