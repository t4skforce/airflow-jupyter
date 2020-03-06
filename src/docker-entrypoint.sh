#!/usr/bin/env bash
set -e
source /root/functions.sh

render-templates

# setup admin user
user-exits ${USER_NAME} || useradd-hub ${USER_NAME}

exec "$@"
