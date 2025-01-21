#!/bin/bash

# Show debugging output
#set -x

# Change to the directory where this script is located
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Install scripts and data.
mkdir -p /usr/local/bin
install borg-backup-create.sh               /usr/local/bin
install borg-backup-init-existing-repo.sh   /usr/local/bin
install borg-backup-init-new-repo.sh        /usr/local/bin
install borg-backup-rsync.sh                /usr/local/bin
cp      borg-backup-readme.rst              /usr/local/bin

# Install Systemd unit files.
cp borg-backup-daily.service  /etc/systemd/system/
cp borg-backup-daily.timer    /etc/systemd/system/

# Reload all Systemd unit files.
systemctl daemon-reload
