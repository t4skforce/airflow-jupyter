#!/usr/bin/env bash
set -e
source /root/functions.sh

render-templates

exec "$@"
