#!/usr/bin/env bash
set -e
source /root/functions.sh

admin-system-user && render-templates

exec "$@"
