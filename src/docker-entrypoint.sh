#!/usr/bin/env bash
set -e
source /root/functions.sh

user-exits ${USER_NAME} || add-hub-user.sh ${USER_NAME} && (echo "${USER_NAME}:${USER_NAME}" | chpasswd)

render-templates

exec "$@"
