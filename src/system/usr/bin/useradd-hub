#!/usr/bin/env bash
set -e
source /root/functions.sh

USERNAME=$1
ACC_FILE="/home/$USER_NAME/work/accounts.md"
if [ "$USERNAME" == "$USER_NAME" ]; then
  (set -xe; useradd --uid $USER_UID --gid $USER_GID --groups sudo,conda --shell ${SHELL-/bin/bash} --create-home --home "/home/$USERNAME" $USERNAME)
  (USER_PASS=${USER_PASS-$(randpw)} && echo "${USER_NAME}:${USER_PASS}" | chpasswd && banner "Username: '$USER_NAME' Password: '$USER_PASS'")
else
  (set -xe; useradd --groups conda --shell ${SHELL-/bin/bash} --create-home --home "/home/$USERNAME" $USERNAME)
fi
mkdir -p "/home/$USERNAME/work"
render-templates "/root/templates/.home/" "/home/$USERNAME/"
chown -R $USERNAME:conda "/home/$USERNAME"
