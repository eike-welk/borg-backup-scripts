#!/bin/bash

# Show debugging output
#set -x

# Change to the directory where this script is located
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Install scripts and data.
mkdir -p /usr/local/bin
install borg-backup-create.sh   /usr/local/bin
install borg-backup-init.sh     /usr/local/bin
install borg-backup-rsync.sh    /usr/local/bin
cp      borg-backup-readme.rst  /usr/local/bin

# Install Systemd unit files.
mkdir -p /usr/local/lib/systemd/system
cp borg-backup-daily.service  /usr/local/lib/systemd/system
cp borg-backup-daily.timer    /usr/local/lib/systemd/system

## Copy into standard Systemd directory instead?
#cp borg-backup-daily.service  /etc/systemd/system/
#cp borg-backup-daily.timer    /etc/systemd/system/

# Reload all Systemd unit files.
systemctl daemon-reload

