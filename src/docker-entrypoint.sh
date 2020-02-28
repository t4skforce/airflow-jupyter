#!/usr/bin/env bash
set -e
source /root/functions.sh

render-templates

user-exits ${USER_NAME} && banner 'Update User' && update-user || (banner 'Setup User' && add-user)

exec "$@"
