#!/usr/bin/env bash
set -e
source /root/functions.sh

user-exits || add-hub-user.sh ${USER_NAME} && echo "${USER_NAME}:${USER_NAME}" | chpasswd

render-templates

exec "$@"
